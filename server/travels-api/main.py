import os
import json
import jwt
import datetime
import mysql.connector
from flask import Flask, request, jsonify
from functools import wraps

# --- Flask App Initialization ---
app = Flask(__name__)

# --- Environment Variable Configuration ---
db_host = os.environ.get("CLOUD_SQL_HOST")
db_user = os.environ.get("CLOUD_SQL_USER")
db_password = os.environ.get("CLOUD_SQL_PASSWORD")
db_name = os.environ.get("CLOUD_SQL_DATABASE")

# JWT Validation Configuration
JWT_SECRET = os.environ.get("JWT_SECRET")
JWT_ALGORITHM = "HS256"

# --- Database Connection ---
def get_db_connection():
    """Function to connect to Cloud SQL"""
    conn = None
    try:
        conn = mysql.connector.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            database=db_name,
            port=3306
        )
        return conn
    except mysql.connector.Error as err:
        print(f"MySQL connection error: {err}")
        return None

# --- JWT Authentication Decorator ---
def token_required(f):
    """Decorator to validate access tokens (issued by other services)"""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            try:
                token = auth_header.split(" ")[1]
            except IndexError:
                return jsonify({"code": 401, "success": False, "msg": "Invalid token format. Use 'Bearer <token>' format."}), 401

        if not token:
            return jsonify({"code": 401, "success": False, "msg": "Authentication token is required in the header. ('Authorization: Bearer <token>')"}), 401

        if not JWT_SECRET:
            print("CRITICAL: JWT_SECRET environment variable is not set.")
            return jsonify({"code": 500, "success": False, "msg": "Server configuration error (JWT Secret missing)"}), 500

        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
            current_user_id = payload['userId']
        except jwt.ExpiredSignatureError:
            return jsonify({"code": 401, "success": False, "msg": "Token has expired."}), 401
        except jwt.InvalidTokenError as e:
            print(f"Invalid Token Error during decode: {e}")
            return jsonify({"code": 401, "success": False, "msg": f"Invalid token: {e}"}), 401
        except Exception as e:
            print(f"Token decoding error: {type(e).__name__} - {e}")
            return jsonify({"code": 401, "success": False, "msg": "An error occurred while processing the token."}), 401

        return f(*args, current_user_id=current_user_id, **kwargs)
    return decorated

# --- API Routes (Registered with Flask app) ---

# 로그인한 사용자의 여행 리스트 조회 (미션 요약 정보 포함)
@app.route('/api/travels', methods=['GET'])
@token_required
def get_travels(current_user_id):
    """로그인한 사용자의 여행 리스트를 조회 (각 여행별 미션 총 개수 및 완료 개수 포함)"""
    user_id = current_user_id
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "success": False, "msg": "데이터베이스 연결 실패"}), 500
        cursor = conn.cursor(dictionary=True)

        # travels 테이블과 missions 테이블을 LEFT JOIN하여 미션 관련 집계 데이터 가져오기
        sql_query = """
            SELECT
                t.id, t.title, t.start_date, t.end_date, t.destination, t.person_count,
                t.brave_level, t.mission_frequency, t.created_at, t.updated_at,
                COUNT(m.id) AS total_missions,
                COALESCE(SUM(CASE WHEN m.is_completed = TRUE THEN 1 ELSE 0 END), 0) AS completed_missions
            FROM travels t
            LEFT JOIN missions m ON t.id = m.travel_id
            WHERE t.user_id = %s
            GROUP BY t.id, t.title, t.start_date, t.end_date, t.destination, t.person_count,
                     t.brave_level, t.mission_frequency, t.created_at, t.updated_at
            ORDER BY t.start_date DESC
        """
        cursor.execute(sql_query, (user_id,))
        travels_raw = cursor.fetchall()

        travel_list = []
        for travel in travels_raw:
            travel_list.append({
                "id": travel['id'],
                "title": travel['title'],
                "destination": travel['destination'],
                "startDate": travel['start_date'].strftime('%Y-%m-%d') if travel['start_date'] else None,
                "endDate": travel['end_date'].strftime('%Y-%m-%d') if travel['end_date'] else None,
                "personCount": travel['person_count'],
                "braveLevel": travel['brave_level'],
                "missionFrequency": travel['mission_frequency'],
                "totalMissions": int(travel['total_missions']),  
                "completedMissions": int(travel['completed_missions']),  
                "createdAt": travel['created_at'].isoformat() if travel['created_at'] else None,
                "updatedAt": travel['updated_at'].isoformat() if travel['updated_at'] else None
            })

        return jsonify({
            "code": 200, "success": True, "msg": "여행 리스트 및 미션 요약 정보 조회 성공", 
            "travelList": travel_list
        }), 200
    except mysql.connector.Error as err:
        print(f"MySQL 쿼리 오류 [GET /travels with mission summary]: {err}") 
        return jsonify({"code": 500, "success": False, "msg": "DB 쿼리 오류"}), 500
    except Exception as e: 
        print(f"여행 리스트 조회 중 일반 오류 발생 [GET /travels with mission summary]: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({"code": 500, "success": False, "msg": "서버 내부 오류"}), 500
    finally:
        if cursor: 
            cursor.close()
        if conn and conn.is_connected(): 
            conn.close()

# Add a new travel for the logged-in user
@app.route('/api/travels', methods=['POST'])
@token_required
def create_travel(current_user_id):
    """Adds new travel information for the logged-in user"""
    if not request.is_json:
        return jsonify({"code": 400, "success": False, "msg": "JSON format required"}), 400
    data = request.get_json()
    user_id = current_user_id

    required_fields = ['title', 'startDate', 'endDate', 'destination', 'personCount', 'braveLevel', 'missionFrequency']
    if not all(field in data for field in required_fields):
        missing = [field for field in required_fields if field not in data]
        return jsonify({"code": 400, "success": False, "msg": f"Missing required fields: {', '.join(missing)}"}), 400

    try:
        title = data['title']
        start_date_str = data['startDate']
        end_date_str = data['endDate']
        destination = data['destination']
        person_count = int(data['personCount'])
        brave_level = int(data['braveLevel'])
        mission_frequency = int(data['missionFrequency'])
        datetime.datetime.strptime(start_date_str, '%Y-%m-%d')
        datetime.datetime.strptime(end_date_str, '%Y-%m-%d')
        if person_count <= 0: raise ValueError("personCount must be greater than 0")
        if not (1 <= brave_level <= 5): raise ValueError("braveLevel must be between 1 and 5")
        if not (0 <= mission_frequency <= 100): raise ValueError("missionFrequency must be between 0 and 100")
    except (ValueError, TypeError) as ve:
        return jsonify({"code": 400, "success": False, "msg": f"Input value error: {ve}"}), 400

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "success": False, "msg": "Database connection failed"}), 500
        cursor = conn.cursor()
        sql = """
            INSERT INTO travels (user_id, title, start_date, end_date, destination,
            person_count, brave_level, mission_frequency, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
        """
        cursor.execute(sql, (user_id, title, start_date_str, end_date_str, destination,
                             person_count, brave_level, mission_frequency))
        conn.commit()
        travel_id = cursor.lastrowid
        return jsonify({"code": 201, "success": True, "msg": "Travel information added successfully", "travelId": travel_id}), 201
    except mysql.connector.Error as err:
        print(f"MySQL INSERT error [POST /travels]: {err}")
        return jsonify({"code": 500, "success": False, "msg": "DB processing error"}), 500
    finally:
        if cursor: cursor.close()
        if conn and conn.is_connected(): conn.close()

# Update specific travel information for the logged-in user
@app.route('/api/travels/<int:travel_id>', methods=['PUT'])
@token_required
def update_travel(current_user_id, travel_id):
    """Modifies specific travel information for the logged-in user"""
    if not request.is_json:
        return jsonify({"code": 400, "success": False, "msg": "JSON format required"}), 400
    data = request.get_json()
    user_id = current_user_id

    required_fields = ['title', 'startDate', 'endDate', 'destination', 'personCount', 'braveLevel', 'missionFrequency']
    if not all(field in data for field in required_fields):
        missing = [field for field in required_fields if field not in data]
        return jsonify({"code": 400, "success": False, "msg": f"Missing required fields: {', '.join(missing)}"}), 400

    try:
        title = data['title']
        start_date_str = data['startDate']
        end_date_str = data['endDate']
        destination = data['destination']
        person_count = int(data['personCount'])
        brave_level = int(data['braveLevel'])
        mission_frequency = int(data['missionFrequency'])
        datetime.datetime.strptime(start_date_str, '%Y-%m-%d')
        datetime.datetime.strptime(end_date_str, '%Y-%m-%d')
        if person_count <= 0: raise ValueError("personCount must be greater than 0")
        if not (1 <= brave_level <= 5): raise ValueError("braveLevel must be between 1 and 5")
        if not (0 <= mission_frequency <= 100): raise ValueError("missionFrequency must be between 0 and 100")
    except (ValueError, TypeError) as ve:
        return jsonify({"code": 400, "success": False, "msg": f"Input value error: {ve}"}), 400

    conn = None
    cursor = None
    cursor_update = None
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "success": False, "msg": "Database connection failed"}), 500
        cursor = conn.cursor(dictionary=True) 

        cursor.execute("SELECT user_id FROM travels WHERE id = %s", (travel_id,))
        travel = cursor.fetchone()

        if not travel:
            return jsonify({"code": 404, "success": False, "msg": "Travel information not found"}), 404
        if travel['user_id'] != user_id:
             return jsonify({"code": 403, "success": False, "msg": "No permission to modify"}), 403

        sql = """
            UPDATE travels SET title = %s, start_date = %s, end_date = %s, destination = %s,
            person_count = %s, brave_level = %s, mission_frequency = %s, updated_at = NOW()
            WHERE id = %s AND user_id = %s
        """
        cursor_update = conn.cursor()
        cursor_update.execute(sql, (title, start_date_str, end_date_str, destination,
                                     person_count, brave_level, mission_frequency,
                                     travel_id, user_id))
        conn.commit()

        return jsonify({"code": 200, "success": True, "msg": f"Travel (ID: {travel_id}) updated successfully"}), 200
    except mysql.connector.Error as err:
        print(f"MySQL UPDATE error [PUT /travels/{travel_id}]: {err}")
        return jsonify({"code": 500, "success": False, "msg": "DB processing error"}), 500
    finally:
        if cursor: cursor.close()
        if cursor_update: cursor_update.close()
        if conn and conn.is_connected(): conn.close()

# Delete specific travel information for the logged-in user
@app.route('/api/travels/<int:travel_id>', methods=['DELETE'])
@token_required
def delete_travel(current_user_id, travel_id):
    """Deletes specific travel information for the logged-in user"""
    user_id = current_user_id
    conn = None
    cursor = None
    cursor_delete = None
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "success": False, "msg": "Database connection failed"}), 500
        cursor = conn.cursor(dictionary=True) 

        cursor.execute("SELECT user_id FROM travels WHERE id = %s", (travel_id,))
        travel = cursor.fetchone()

        if not travel:
            return jsonify({"code": 404, "success": False, "msg": "Travel information not found"}), 404
        if travel['user_id'] != user_id:
             return jsonify({"code": 403, "success": False, "msg": "No permission to delete"}), 403

        cursor_delete = conn.cursor()
        cursor_delete.execute("DELETE FROM travels WHERE id = %s AND user_id = %s", (travel_id, user_id))
        conn.commit()
        deleted_count = cursor_delete.rowcount

        if deleted_count == 0:
             print(f"Warning: Delete for ID {travel_id} affected 0 rows after ownership check.")
             return jsonify({"code": 404, "success": False, "msg": "Travel information to delete not found or already deleted"}), 404

        return jsonify({"code": 200, "success": True, "msg": f"Travel (ID: {travel_id}) deleted successfully"}), 200
    except mysql.connector.Error as err:
        print(f"MySQL DELETE error [DELETE /travels/{travel_id}]: {err}")
        return jsonify({"code": 500, "success": False, "msg": "DB processing error"}), 500
    finally:
        if cursor: cursor.close()
        if cursor_delete: cursor_delete.close()
        if conn and conn.is_connected(): conn.close()

# --- Cloud Functions Entry Point Function ---
def main(request):
    """Entry point function for Cloud Functions HTTP trigger. Forwards request to the Flask app."""
    with app.request_context(request.environ):
        return app.full_dispatch_request()