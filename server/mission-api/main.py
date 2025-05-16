import os
import json
import jwt
import datetime
import mysql.connector
from flask import Flask, request, jsonify
from functools import wraps

app = Flask(__name__)

# --- Environment Variable Configuration ---
db_host = os.environ.get("CLOUD_SQL_HOST")
db_user = os.environ.get("CLOUD_SQL_USER")
db_password = os.environ.get("CLOUD_SQL_PASSWORD")
db_name = os.environ.get("CLOUD_SQL_DATABASE")
JWT_SECRET = os.environ.get("JWT_SECRET")
JWT_ALGORITHM = "HS256"

# --- Database Connection ---
def get_db_connection():
    """Function to connect to Cloud SQL"""
    conn = None
    try:
        conn = mysql.connector.connect(
            host=db_host, user=db_user, password=db_password,
            database=db_name, port=3306
        )
        return conn
    except mysql.connector.Error as err:
        print(f"MySQL connection error: {err}")
        return None

# --- JWT Authentication Decorator ---
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            try: token = auth_header.split(" ")[1]
            except IndexError: return jsonify({"code": 401, "success": False, "msg": "유효하지 않은 토큰 형식"}), 401 # Invalid token format
        if not token: return jsonify({"code": 401, "success": False, "msg": "인증 토큰 필요"}), 401 # Authentication token required
        if not JWT_SECRET:
            print("CRITICAL: JWT_SECRET environment variable is not set.")
            return jsonify({"code": 500, "success": False, "msg": "서버 설정 오류 (JWT Secret)"}), 500 # Server configuration error (JWT Secret)
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
            kwargs['current_user_id'] = payload['userId']
        except jwt.ExpiredSignatureError: return jsonify({"code": 401, "success": False, "msg": "토큰 만료"}), 401 # Token expired
        except jwt.InvalidTokenError as e: return jsonify({"code": 401, "success": False, "msg": f"유효하지 않은 토큰: {e}"}), 401 # Invalid token
        except Exception as e: return jsonify({"code": 401, "success": False, "msg": "토큰 처리 오류"}), 401 # Token processing error
        return f(*args, **kwargs)
    return decorated

# --- API Routes ---

# === Mission (Missions) related API ===

@app.route('/api/travels/<int:travel_id>/missions', methods=['GET'])
@token_required
def get_missions_for_travel(current_user_id, travel_id):
    """Retrieve mission list and summary (total/completed counts) belonging to a specific travel (includes ownership check)""" # 설명 수정
    user_id = current_user_id
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn: return jsonify({"code": 500, "success": False, "msg": "DB 연결 실패"}), 500 # DB connection failed

        cursor = conn.cursor(dictionary=True)

        # 1. Check if the requesting user is the owner of the travel
        cursor.execute("SELECT user_id FROM travels WHERE id = %s", (travel_id,))
        travel = cursor.fetchone()

        if not travel:
            return jsonify({"code": 404, "success": False, "msg": f"Travel ID {travel_id} 없음"}), 404 # Travel ID not found
        if travel['user_id'] != user_id:
            return jsonify({"code": 403, "success": False, "msg": "해당 여행의 미션 조회 권한 없음"}), 403 # No permission to view missions for this travel

        # 2. Retrieve total and completed mission counts
        sql_counts = """
            SELECT
                COUNT(*) AS total_missions,
                COALESCE(SUM(CASE WHEN is_completed = TRUE THEN 1 ELSE 0 END), 0) AS completed_missions
            FROM missions
            WHERE travel_id = %s
        """
        cursor.execute(sql_counts, (travel_id,))
        mission_counts = cursor.fetchone()

        total_missions = int(mission_counts['total_missions'])
        completed_missions = int(mission_counts['completed_missions'])

        # 3. Retrieve mission list with the corresponding travel ID
        cursor.execute("""
            SELECT id, travel_id, title, content, is_completed,
                   completion_image, created_at, updated_at
            FROM missions
            WHERE travel_id = %s
            ORDER BY created_at ASC
        """, (travel_id,))
        missions_raw = cursor.fetchall()

        # Format results
        mission_list = []
        for mission in missions_raw:
            mission_list.append({
                "id": mission['id'],
                "travelId": mission['travel_id'],
                "title": mission['title'],
                "content": mission['content'],
                "isCompleted": mission['is_completed'],
                "completionImage": mission['completion_image'],
                "createdAt": mission['created_at'].isoformat() if mission['created_at'] else None,
                "updatedAt": mission['updated_at'].isoformat() if mission['updated_at'] else None
            })

        return jsonify({
            "code": 200,
            "success": True,
            "msg": "미션 리스트 및 요약 정보 조회 성공",
            "summary": { 
                "totalMissions": total_missions,
                "completedMissions": completed_missions
            },
            "missionList": mission_list
        }), 200

    except mysql.connector.Error as err:
        print(f"MySQL query error [GET /travels/{travel_id}/missions with summary]: {err}") # 로그 메시지 수정
        return jsonify({"code": 500, "success": False, "msg": "DB 쿼리 오류"}), 500 # DB query error
    except Exception as e:
        print(f"Get missions error [with summary]: {e}")
        return jsonify({"code": 500, "success": False, "msg": "서버 내부 오류"}), 500 # Internal server error
    finally:
        if cursor:
            try: cursor.close()
            except Exception as cursor_err: print(f"Get mission (with summary) cursor closing error: {cursor_err}") # 로그 메시지 수정
        if conn and conn.is_connected():
            try: conn.close()
            except Exception as conn_err: print(f"DB connection closing error for get_missions (with summary): {conn_err}") # 로그 메시지 수정

@app.route('/api/missions/<int:mission_id>/completion-image', methods=['POST'])
@token_required
def save_completion_image(current_user_id, mission_id):
    """Save/Update completion image URL for a specific mission (includes ownership check)"""
    if not request.is_json:
        return jsonify({"code": 400, "success": False, "msg": "JSON 형식 필요"}), 400 # JSON format required
    data = request.get_json()
    user_id = current_user_id

    completion_image_url = data.get('completionImageUrl')
    if not completion_image_url:
        return jsonify({"code": 400, "success": False, "msg": "필수 필드 누락: completionImageUrl"}), 400 # Missing required field: completionImageUrl
    if not isinstance(completion_image_url, str) or len(completion_image_url) > 500:
        return jsonify({"code": 400, "success": False, "msg": "completionImageUrl 형식이 잘못되었거나 너무 깁니다."}), 400 # completionImageUrl format is incorrect or too long

    conn = None
    cursor_check = None
    cursor_update = None
    try:
        conn = get_db_connection()
        if not conn: return jsonify({"code": 500, "success": False, "msg": "DB 연결 실패"}), 500 # DB connection failed
        cursor_check = conn.cursor(dictionary=True)

        # 1. Check mission existence and ownership (using JOIN)
        sql_check = "SELECT t.user_id FROM missions m JOIN travels t ON m.travel_id = t.id WHERE m.id = %s"
        cursor_check.execute(sql_check, (mission_id,))
        mission_owner = cursor_check.fetchone()
        try: cursor_check.close()
        except Exception as cursor_err: print(f"Check cursor (image) closing error: {cursor_err}")
        cursor_check = None 

        if not mission_owner:
            return jsonify({"code": 404, "success": False, "msg": f"Mission ID {mission_id} 없음"}), 404 # Mission ID not found
        if mission_owner['user_id'] != user_id:
            return jsonify({"code": 403, "success": False, "msg": "해당 미션에 접근 권한 없음"}), 403 # No permission to access this mission

        # 2. Update image URL (schema column name: completion_image)
        sql_update = "UPDATE missions SET completion_image = %s, updated_at = NOW() WHERE id = %s"
        cursor_update = conn.cursor()
        cursor_update.execute(sql_update, (completion_image_url, mission_id))
        conn.commit()

        return jsonify({"code": 200, "success": True, "msg": f"미션(ID: {mission_id}) 이미지 저장 성공"}), 200 # Mission (ID: {mission_id}) image saved successfully

    except mysql.connector.Error as err:
        print(f"MySQL UPDATE error [POST /missions/{mission_id}/completion-image]: {err}")
        return jsonify({"code": 500, "success": False, "msg": "DB 처리 오류"}), 500 # DB processing error
    except Exception as e:
        print(f"Save completion image error: {e}")
        return jsonify({"code": 500, "success": False, "msg": "서버 내부 오류"}), 500 # Internal server error
    finally:
        if cursor_check: 
             try: cursor_check.close()
             except Exception as cursor_err: print(f"Check cursor (image) finally closing error: {cursor_err}")
        if cursor_update:
            try: cursor_update.close()
            except Exception as cursor_err: print(f"Update cursor (image) closing error: {cursor_err}")
        if conn and conn.is_connected():
            try: conn.close()
            except Exception as conn_err: print(f"DB connection closing error: {conn_err}")


@app.route('/api/missions/<int:mission_id>/complete', methods=['PUT'])
@token_required
def complete_mission_status(current_user_id, mission_id):
    """Change the status of a specific mission to completed (includes ownership check)"""
    user_id = current_user_id
    conn = None
    cursor_check = None
    cursor_update = None
    try:
        conn = get_db_connection()
        if not conn: return jsonify({"code": 500, "success": False, "msg": "DB 연결 실패"}), 500 # DB connection failed
        cursor_check = conn.cursor(dictionary=True)

        # 1. Check mission existence and ownership (using JOIN)
        sql_check = "SELECT t.user_id, m.is_completed FROM missions m JOIN travels t ON m.travel_id = t.id WHERE m.id = %s"
        cursor_check.execute(sql_check, (mission_id,))
        mission_info = cursor_check.fetchone()
        try: cursor_check.close()
        except Exception as cursor_err: print(f"Check cursor (complete) closing error: {cursor_err}")
        cursor_check = None 

        if not mission_info:
            return jsonify({"code": 404, "success": False, "msg": f"Mission ID {mission_id} 없음"}), 404 # Mission ID not found
        if mission_info['user_id'] != user_id:
            return jsonify({"code": 403, "success": False, "msg": "미션 완료 권한 없음"}), 403 # No permission to complete mission

        if mission_info['is_completed']:
            return jsonify({"code": 200, "success": True, "msg": f"미션(ID: {mission_id})은 이미 완료 상태입니다."}), 200 # Mission (ID: {mission_id}) is already completed.

        # 2. Update mission status
        sql_update = """
            UPDATE missions SET
                is_completed = TRUE,
                updated_at = NOW()
            WHERE id = %s
        """
        cursor_update = conn.cursor()
        cursor_update.execute(sql_update, (mission_id,))
        conn.commit()

        return jsonify({"code": 200, "success": True, "msg": f"미션(ID: {mission_id}) 완료 처리 성공"}), 200 # Mission (ID: {mission_id}) marked as completed successfully

    except mysql.connector.Error as err:
        print(f"MySQL UPDATE error [PUT /missions/{mission_id}/complete]: {err}")
        return jsonify({"code": 500, "success": False, "msg": "DB 처리 오류"}), 500 # DB processing error
    except Exception as e:
        print(f"Complete mission status error: {e}")
        return jsonify({"code": 500, "success": False, "msg": "서버 내부 오류"}), 500 # Internal server error
    finally:
        if cursor_check:
            try: cursor_check.close()
            except Exception as cursor_err: print(f"Check cursor (complete) finally closing error: {cursor_err}")
        if cursor_update:
            try: cursor_update.close()
            except Exception as cursor_err: print(f"Update cursor (complete) closing error: {cursor_err}")
        if conn and conn.is_connected():
            try: conn.close()
            except Exception as conn_err: print(f"DB connection closing error: {conn_err}")

# --- Cloud Functions Entry Point Function ---
def main(request):
    """Entry point function for Cloud Functions HTTP trigger."""
    with app.request_context(request.environ):
        return app.full_dispatch_request()