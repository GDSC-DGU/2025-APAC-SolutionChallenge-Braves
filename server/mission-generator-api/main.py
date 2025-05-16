import os
import json
import jwt
import datetime
import uuid
import mysql.connector
import requests
from flask import Flask, request, jsonify
from functools import wraps

from timezonefinder import TimezoneFinder
import pytz

app = Flask(__name__)

# --- 환경 변수 설정 ---
db_host = os.environ.get("CLOUD_SQL_HOST")
db_user = os.environ.get("CLOUD_SQL_USER")
db_password = os.environ.get("CLOUD_SQL_PASSWORD")
db_name = os.environ.get("CLOUD_SQL_DATABASE")
JWT_SECRET = os.environ.get("JWT_SECRET")
JWT_ALGORITHM = "HS256"
AI_MISSION_SERVICE_URL = os.environ.get("AI_MISSION_SERVICE_URL")

# --- TimezoneFinder 초기화 ---
tf = TimezoneFinder()

# --- Firebase Admin SDK 초기화 ---
import firebase_admin
from firebase_admin import credentials, messaging
try:
    if not firebase_admin._apps:
        firebase_admin.initialize_app()
    print("Firebase Admin SDK initialized.")
except Exception as e:
    print(f"Error initializing Firebase Admin SDK: {e}")


# --- 데이터베이스 연결 ---
def get_db_connection():
    conn = None
    try:
        conn = mysql.connector.connect(
            host=db_host, user=db_user, password=db_password,
            database=db_name, port=3306
        )
        return conn
    except mysql.connector.Error as err:
        print(f"MySQL 연결 오류: {err}")
        return None

# --- JWT 인증 데코레이터 ---
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            try: token = auth_header.split(" ")[1]
            except IndexError: return jsonify({"code": 401, "success": False, "msg": "유효하지 않은 토큰 형식"}), 401
        if not token: return jsonify({"code": 401, "success": False, "msg": "인증 토큰 필요"}), 401
        if not JWT_SECRET or JWT_SECRET == "change-this-in-prod":
             print("CRITICAL: JWT_SECRET 환경 변수가 설정되지 않았거나 기본값을 사용 중입니다.")
             return jsonify({"code": 500, "success": False, "msg": "서버 설정 오류 (JWT Secret)"}), 500
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
            kwargs['current_user_id'] = payload['userId']
        except jwt.ExpiredSignatureError: return jsonify({"code": 401, "success": False, "msg": "토큰 만료"}), 401
        except jwt.InvalidTokenError as e: return jsonify({"code": 401, "success": False, "msg": f"유효하지 않은 토큰: {e}"}), 401
        except Exception as e: return jsonify({"code": 401, "success": False, "msg": "토큰 처리 오류"}), 401
        return f(*args, **kwargs)
    return decorated

# --- 함수 ---
def _get_travel_and_user_info(cursor, user_id, travel_id):
    """여행 정보(소유권 확인 포함) 및 사용자 기본 정보 조회"""
    # 여행 정보 조회
    cursor.execute("SELECT title, brave_level, person_count FROM travels WHERE id = %s AND user_id = %s", (travel_id, user_id))
    travel_record = cursor.fetchone()
    if not travel_record:
        raise ValueError(f"Travel ID {travel_id}를 찾을 수 없거나 사용자 소유가 아님")

    # 사용자 정보 조회 (fcm_token 포함)
    cursor.execute("SELECT username, fcm_token FROM users WHERE id = %s", (user_id,))
    user_record = cursor.fetchone()
    if not user_record:
        raise ValueError("사용자 정보를 찾을 수 없음")

    traveler_info_dict = {
        "username": user_record.get("username", "Brave Traveler"),
        "party_size": travel_record['person_count']
    }
    
    return {
        "trip_information": travel_record['title'],
        "brave_scale": str(travel_record['brave_level']),
        "traveler_information_str": json.dumps(traveler_info_dict),
        "user_fcm_token": user_record.get('fcm_token')
    }

def _get_time_for_ai(lat_f, lon_f):
    """주어진 위도/경도 기반으로 시간 정보 생성"""
    current_time_for_ai = ""
    timezone_str = tf.timezone_at(lng=lon_f, lat=lat_f)
    if timezone_str:
        user_timezone = pytz.timezone(timezone_str)
        current_time_for_ai = datetime.datetime.now(user_timezone).isoformat()
        print(f"Timezone for location: {timezone_str}, Current time at location: {current_time_for_ai}")
    else:
        current_time_for_ai = datetime.datetime.now(datetime.timezone.utc).isoformat()
        print(f"Warning: Timezone not found for lat/lon. Using UTC for AI: {current_time_for_ai}")
    return current_time_for_ai

def _call_ai_mission_service(ai_payload):
    if not AI_MISSION_SERVICE_URL:
        print("CRITICAL: AI_MISSION_SERVICE_URL 환경 변수가 설정되지 않았습니다.")
        raise ValueError("AI 서비스 URL 미설정")
    print(f"Calling AI Mission Service with payload: {ai_payload}")
    try:
        ai_response = requests.post(AI_MISSION_SERVICE_URL, json=ai_payload, timeout=30)
        ai_response.raise_for_status()
        return ai_response.json()
    except Exception as e:
        print(f"AI Mission Service 호출 중 예외 발생: {e}")
        raise

def _extract_mission_from_ai_response(ai_mission_data):
    if not ai_mission_data or ai_mission_data.get("status") != "success" or "mission" not in ai_mission_data:
        msg = ai_mission_data.get('msg', 'Unknown error') if ai_mission_data else 'No data'
        print(f"AI Mission Service가 성공 응답을 반환하지 않음: {msg}")
        raise ValueError(f"AI 서비스 처리 실패: {msg}")
    mission_details = ai_mission_data['mission']
    mission_title = mission_details.get('name')
    mission_content = mission_details.get('how_to_play')
    if not mission_title or not mission_content:
        raise ValueError("AI 서비스로부터 유효한 미션 제목/내용을 받지 못함")
    return mission_title, mission_content, mission_details

def _upsert_location_log(cursor, user_id, lat_f, lon_f, acc_f):
    """location_logs 테이블에 위치 정보 UPSERT"""
    upsert_sql = """
        INSERT INTO location_logs (user_id, latitude, longitude, accuracy, updated_at)
        VALUES (%s, %s, %s, %s, NOW())
        ON DUPLICATE KEY UPDATE
            latitude = VALUES(latitude),
            longitude = VALUES(longitude),
            accuracy = VALUES(accuracy),
            updated_at = NOW()
    """
    cursor.execute(upsert_sql, (user_id, lat_f, lon_f, acc_f))
    print(f"Location log for user_id {user_id} saved/updated.")


# --- API 라우트 ---

# 1. 사용자가 직접 AI 미션 생성 및 즉시 저장 요청
@app.route('/api/travels/<int:travel_id>/generate-direct-ai-mission', methods=['POST'])
@token_required
def generate_direct_ai_mission(current_user_id, travel_id):
    user_id = current_user_id

    # 클라이언트로부터 위치 정보 받기
    if not request.is_json:
        return jsonify({"code": 400, "success": False, "msg": "JSON 형식 필요"}), 400
    client_data = request.get_json()
    latitude_str = client_data.get('latitude')
    longitude_str = client_data.get('longitude')
    accuracy_str = client_data.get('accuracy')

    if latitude_str is None or longitude_str is None:
        return jsonify({"code": 400, "success": False, "msg": "필수 파라미터 누락: latitude, longitude"}), 400
    try:
        lat_f = float(latitude_str)
        lon_f = float(longitude_str)
        acc_f = float(accuracy_str) if accuracy_str is not None else None
        if not (-90 <= lat_f <= 90): raise ValueError("latitude 범위 초과")
        if not (-180 <= lon_f <= 180): raise ValueError("longitude 범위 초과")
        if acc_f is not None and acc_f < 0: raise ValueError("accuracy는 음수일 수 없음")
    except (ValueError, TypeError) as ve:
        return jsonify({"code": 400, "success": False, "msg": f"위치 정보 유효성 오류: {ve}"}), 400

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn: return jsonify({"code": 500, "success": False, "msg": "DB 연결 실패"}), 500
        cursor = conn.cursor(dictionary=True)

        # 받은 위치 정보를 location_logs 테이블에 저장/업데이트
        _upsert_location_log(cursor, user_id, lat_f, lon_f, acc_f)
        
        # 여행 및 사용자 정보 조회
        common_data = _get_travel_and_user_info(cursor, user_id, travel_id)
        
        # 시간 정보 생성 (클라이언트가 제공한 위치 기반)
        current_time_for_ai = _get_time_for_ai(lat_f, lon_f)
        
        ai_payload = {
            "latitude": str(lat_f),
            "longitude": str(lon_f),
            "traveler_information": common_data["traveler_information_str"],
            "current_time": current_time_for_ai,
            "trip_information": common_data["trip_information"],
            "brave_scale": common_data["brave_scale"]
        }
        
        ai_mission_data = _call_ai_mission_service(ai_payload)
        mission_title, mission_content, mission_details_full = _extract_mission_from_ai_response(ai_mission_data)

        sql_insert_mission = "INSERT INTO missions (travel_id, title, content, created_at, updated_at) VALUES (%s, %s, %s, NOW(), NOW())"
        cursor.execute(sql_insert_mission, (travel_id, mission_title, mission_content))
        new_mission_id = cursor.lastrowid
        
        conn.commit() # 모든 DB 작업 성공 후 커밋
        
        return jsonify({
            "code": 201, 
            "success": True, 
            "msg": "AI 미션 직접 생성 및 저장 성공",
            "missionId": new_mission_id, 
            "title": mission_title,     # 수정: 미션 제목만 반환
            "content": mission_content  # 수정: 미션 내용만 반환
        }), 201

    except ValueError as ve: # 헬퍼 함수에서 발생한 ValueError 처리
        status_code = 500 # 기본값
        if "Travel ID" in str(ve) or "사용자 정보" in str(ve): status_code = 404
        elif "AI 서비스" in str(ve): status_code = 502
        return jsonify({"code": status_code, "success": False, "msg": str(ve)}), status_code
    except requests.exceptions.RequestException as req_err: # AI 서비스 호출 자체 오류
        return jsonify({"code": 502, "success": False, "msg": f"미션 생성 서비스 호출 실패: {req_err}"}), 502
    except mysql.connector.Error as db_err:
        if conn: conn.rollback()
        print(f"MySQL 오류 [POST /generate-direct-ai-mission]: {db_err}")
        return jsonify({"code": 500, "success": False, "msg": "DB 처리 오류"}), 500
    except Exception as e:
        if conn: conn.rollback()
        print(f"Generate direct AI mission 오류: {type(e).__name__} - {e}")
        import traceback; traceback.print_exc()
        return jsonify({"code": 500, "success": False, "msg": "서버 내부 오류"}), 500
    finally:
        if cursor: 
            try: cursor.close()
            except Exception as e: print(f"DB 커서 (direct_ai_mission) finally: {e}")
        if conn and conn.is_connected():
            try: conn.close(); print("DB connection (direct_ai_mission) closed.")
            except Exception as e: print(f"DB 연결 (direct_ai_mission) finally: {e}")

# 2. AI 미션 제안 및 FCM 발송
@app.route('/api/travels/<int:travel_id>/propose-ai-mission', methods=['POST'])
@token_required
def propose_ai_mission(current_user_id, travel_id):
    user_id = current_user_id
    if not request.is_json: return jsonify({"code": 400, "success": False, "msg": "JSON 형식 필요"}), 400
    client_data = request.get_json()
    latitude_str = client_data.get('latitude')
    longitude_str = client_data.get('longitude')
    accuracy_str = client_data.get('accuracy')

    if latitude_str is None or longitude_str is None: return jsonify({"code": 400, "success": False, "msg": "필수 파라미터 누락: latitude, longitude"}), 400
    try:
        lat_f = float(latitude_str); lon_f = float(longitude_str)
        acc_f = float(accuracy_str) if accuracy_str is not None else None
        if not (-90 <= lat_f <= 90): raise ValueError("latitude 범위 초과")
        if not (-180 <= lon_f <= 180): raise ValueError("longitude 범위 초과")
        if acc_f is not None and acc_f < 0: raise ValueError("accuracy는 음수일 수 없음")
    except (ValueError, TypeError) as ve:
        return jsonify({"code": 400, "success": False, "msg": f"위치 정보 유효성 오류: {ve}"}), 400
    
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn: return jsonify({"code": 500, "success": False, "msg": "DB 연결 실패"}), 500
        cursor = conn.cursor(dictionary=True)

        _upsert_location_log(cursor, user_id, lat_f, lon_f, acc_f)
        common_data = _get_travel_and_user_info(cursor, user_id, travel_id)
        user_fcm_token = common_data.pop('user_fcm_token')
        current_time_for_ai = _get_time_for_ai(lat_f, lon_f)
        
        ai_payload = {
            "latitude": str(lat_f), "longitude": str(lon_f),
            "traveler_information": common_data["traveler_information_str"],
            "current_time": current_time_for_ai,
            "trip_information": common_data["trip_information"],
            "brave_scale": common_data["brave_scale"]
        }
        
        ai_mission_data = _call_ai_mission_service(ai_payload)
        mission_title, mission_content, _ = _extract_mission_from_ai_response(ai_mission_data)

        proposal_id = str(uuid.uuid4())
        expires_at = datetime.datetime.utcnow() + datetime.timedelta(hours=24)
        sql_insert_proposal = "INSERT INTO mission_proposals (id, user_id, travel_id, title, content, raw_ai_response, expires_at, created_at) VALUES (%s, %s, %s, %s, %s, %s, %s, NOW())"
        cursor.execute(sql_insert_proposal, (proposal_id, user_id, travel_id, mission_title, mission_content, json.dumps(ai_mission_data), expires_at))
        
        conn.commit() # 위치 로그, 미션 제안 모두 커밋

        if user_fcm_token and firebase_admin._apps:
            try:
                message = messaging.Message(
                    data={ 'proposal_id': proposal_id, 'travel_id': str(travel_id), 'mission_title': mission_title, 'type': 'MISSION_PROPOSAL'},
                    token=user_fcm_token,
                )
                # --- Notification 페이로드만 보내기 ---
                # print(f"FCM TEST (Notification-only): Sending to token: {user_fcm_token}") # 테스트 로그 추가
                # message = messaging.Message(
                #     notification=messaging.Notification(title="[백엔드 테스트] 알림 제목", body="이것은 백엔드에서 보낸 알림 전용 메시지입니다."),
                #     token=user_fcm_token,
                # )
                fcm_response = messaging.send(message); print('Successfully sent FCM message:', fcm_response)
            except Exception as fcm_err: print(f"Error sending FCM message: {fcm_err}")
        else: print(f"User {user_id} FCM token not found or Firebase not init. Skipping FCM.")
            
        return jsonify({"code": 202, "success": True, "msg": "미션 제안 생성 및 알림 시도 완료", "proposalId": proposal_id}), 202
    except ValueError as ve:
        if conn: conn.rollback()
        status_code = 404 if "Travel ID" in str(ve) or "사용자 정보" in str(ve) else 502
        return jsonify({"code": status_code, "success": False, "msg": str(ve)}), status_code
    except requests.exceptions.RequestException as req_err:
        if conn: conn.rollback()
        return jsonify({"code": 502, "success": False, "msg": f"미션 제안 서비스 호출 실패: {req_err}"}), 502
    except mysql.connector.Error as db_err:
        if conn: conn.rollback()
        print(f"MySQL 오류 [POST /propose-ai-mission]: {db_err}")
        return jsonify({"code": 500, "success": False, "msg": "DB 처리 오류"}), 500
    except Exception as e:
        if conn: conn.rollback()
        print(f"Propose AI mission 오류: {type(e).__name__} - {e}")
        import traceback; traceback.print_exc()
        return jsonify({"code": 500, "success": False, "msg": "서버 내부 오류"}), 500
    finally:
        if cursor: 
            try: cursor.close()
            except Exception as e: print(f"DB 커서 (accept_proposal) finally 오류: {e}")
        if conn and conn.is_connected():
            try: conn.close(); print("DB connection (accept_proposal) closed.")
            except Exception as e: print(f"DB 연결 (accept_proposal) finally 오류: {e}")

# 3. 사용자가 미션 제안 수락
@app.route('/api/mission-proposals/<string:proposal_id>/accept', methods=['POST'])
@token_required
def accept_mission_proposal(current_user_id, proposal_id):
    user_id = current_user_id
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn: return jsonify({"code": 500, "success": False, "msg": "DB 연결 실패"}), 500
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT travel_id, title, content FROM mission_proposals WHERE id = %s AND user_id = %s AND expires_at > NOW()", (proposal_id, user_id))
        proposal = cursor.fetchone()
        if not proposal: return jsonify({"code": 404, "success": False, "msg": "유효한 미션 제안을 찾을 수 없거나 만료됨"}), 404
        
        travel_id = proposal['travel_id']; mission_title = proposal['title']; mission_content = proposal['content']
        sql_insert_mission = "INSERT INTO missions (travel_id, title, content, created_at, updated_at) VALUES (%s, %s, %s, NOW(), NOW())"
        cursor.execute(sql_insert_mission, (travel_id, mission_title, mission_content))
        new_mission_id = cursor.lastrowid
        cursor.execute("DELETE FROM mission_proposals WHERE id = %s", (proposal_id,))
        conn.commit()
        return jsonify({
            "code": 201,
            "success": True,
            "msg": "미션 수락 및 저장 성공",
            "missionId": new_mission_id,
            "title": mission_title,
            "content": mission_content 
        }), 201
    except mysql.connector.Error as db_err:
        if conn: conn.rollback()
        print(f"MySQL 오류 [POST /accept-proposal]: {db_err}")
        return jsonify({"code": 500, "success": False, "msg": "DB 처리 오류"}), 500
    except Exception as e:
        if conn: conn.rollback()
        print(f"Accept mission proposal 오류: {e}")
        import traceback; traceback.print_exc()
        return jsonify({"code": 500, "success": False, "msg": "서버 내부 오류"}), 500
    finally:
        if cursor: 
            try: cursor.close()
            except Exception as e: print(f"DB 커서 (accept_proposal) finally 오류: {e}")
        if conn and conn.is_connected():
            try: conn.close(); print("DB connection (accept_proposal) closed.")
            except Exception as e: print(f"DB 연결 (accept_proposal) finally 오류: {e}")

# === 사용자 상태 업데이트 API (FCM 토큰 전용) ===
@app.route('/api/user-status', methods=['POST'])
@token_required
def update_user_status(current_user_id):
    """클라이언트로부터 받은 FCM 토큰을 DB에 저장/업데이트"""
    user_id = current_user_id

    if not request.is_json:
        return jsonify({"code": 400, "success": False, "msg": "JSON 형식 필요"}), 400
    
    data = request.get_json()
    fcm_token_from_client = data.get('fcmToken')

    if fcm_token_from_client is None: 
        return jsonify({"code": 400, "success": False, "msg": "필수 필드 누락: fcmToken"}), 400
    
    if not isinstance(fcm_token_from_client, str) or len(fcm_token_from_client) > 255: # DB 스키마 길이 고려
        return jsonify({"code": 400, "success": False, "msg": "fcmToken 형식이 잘못되었거나 너무 깁니다."}), 400
    
    fcm_token_to_save = fcm_token_from_client if fcm_token_from_client else None

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn: 
            return jsonify({"code": 500, "success": False, "msg": "DB 연결 실패"}), 500
        cursor = conn.cursor()

        sql_update_fcm = "UPDATE users SET fcm_token = %s, updated_at = NOW() WHERE id = %s"
        cursor.execute(sql_update_fcm, (fcm_token_to_save, user_id))
        
        conn.commit()
        
        if fcm_token_from_client:
            msg = "FCM 토큰이 성공적으로 업데이트되었습니다."
        else:
            msg = "FCM 토큰이 성공적으로 제거되었습니다."
            
        return jsonify({"code": 200, "success": True, "msg": msg}), 200

    except mysql.connector.Error as db_err:
        if conn: conn.rollback()
        print(f"MySQL 오류 [POST /user-status - FCM Update]: {db_err}")
        return jsonify({"code": 500, "success": False, "msg": "DB 처리 오류"}), 500
    except Exception as e:
        if conn: conn.rollback()
        print(f"Update user status (FCM only) 오류: {type(e).__name__} - {e}")
        import traceback; traceback.print_exc()
        return jsonify({"code": 500, "success": False, "msg": "서버 내부 오류"}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception as e: print(f"DB 커서 (user-status/FCM) finally 오류: {e}")
        if conn and conn.is_connected():
            try: conn.close(); print("DB connection (user-status/FCM) closed.")
            except Exception as e: print(f"DB 연결 (user-status/FCM) finally 오류: {e}")

# --- Cloud Functions Entry Point Function ---
def main(request_obj):
    with app.request_context(request_obj.environ):
        return app.full_dispatch_request()