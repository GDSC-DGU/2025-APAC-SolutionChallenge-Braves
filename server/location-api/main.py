import os
import json
import jwt
import datetime # JWT 검증 시 사용될 수 있음
# import uuid # 이 코드에서는 필요 없음
import mysql.connector
from flask import Flask, request, jsonify
from functools import wraps

app = Flask(__name__)

# --- 환경 변수 설정 ---
# Cloud Functions 환경 변수에서 설정 필요
db_host = os.environ.get("CLOUD_SQL_HOST") # 예: 172.19.112.3 (내부 IP 사용 시)
db_user = os.environ.get("CLOUD_SQL_USER")
db_password = os.environ.get("CLOUD_SQL_PASSWORD") # Secret Manager 권장
db_name = os.environ.get("CLOUD_SQL_DATABASE") # 예: braves
JWT_SECRET = os.environ.get("JWT_SECRET", "change-this-in-prod") # 중요: 다른 서비스와 동일한 키 사용
JWT_ALGORITHM = "HS256"

# --- 데이터베이스 연결 ---
def get_db_connection():
    """Cloud SQL에 연결하는 함수"""
    conn = None
    try:
        conn = mysql.connector.connect(
            host=db_host, user=db_user, password=db_password,
            database=db_name, port=3306
        )
        # autocommit은 기본값이 False 이므로 명시적 commit 필요
        return conn
    except mysql.connector.Error as err:
        print(f"MySQL 연결 오류: {err}")
        return None

# --- JWT 인증 데코레이터 ---
def token_required(f):
    """액세스 토큰(다른 서비스에서 발급)을 검증하는 데코레이터"""
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
            # 사용자 ID를 kwargs에 추가하여 전달
            kwargs['current_user_id'] = payload['userId']
        except jwt.ExpiredSignatureError: return jsonify({"code": 401, "success": False, "msg": "토큰 만료"}), 401
        except jwt.InvalidTokenError as e: return jsonify({"code": 401, "success": False, "msg": f"유효하지 않은 토큰: {e}"}), 401
        except Exception as e: return jsonify({"code": 401, "success": False, "msg": "토큰 처리 오류"}), 401
        return f(*args, **kwargs)
    return decorated

# --- API 라우트 ---

# === 사용자 현재/최신 위치 정보 저장/업데이트 API ===
@app.route('/api/location-logs', methods=['POST'])
@token_required
def upsert_location_log(current_user_id):
    """클라이언트로부터 받은 현재 위치 정보를 DB에 저장 또는 업데이트 (UPSERT)"""
    user_id = current_user_id

    if not request.is_json:
        return jsonify({"code": 400, "success": False, "msg": "JSON 형식 필요"}), 400

    # 이제 배열이 아닌 단일 객체를 받음
    location_data = request.get_json()
    if not isinstance(location_data, dict):
         return jsonify({"code": 400, "success": False, "msg": "요청 본문은 JSON 객체여야 합니다."}), 400

    latitude = location_data.get('latitude')
    longitude = location_data.get('longitude')
    accuracy = location_data.get('accuracy') # 선택 사항

    # 필수 필드 및 유효성 검증
    if latitude is None or longitude is None:
        return jsonify({"code": 400, "success": False, "msg": "필수 필드 누락: latitude, longitude"}), 400

    try:
        lat_f = float(latitude)
        lon_f = float(longitude)
        acc_f = float(accuracy) if accuracy is not None else None

        if not (-90 <= lat_f <= 90): raise ValueError("latitude 범위 초과 (-90 ~ 90)")
        if not (-180 <= lon_f <= 180): raise ValueError("longitude 범위 초과 (-180 ~ 180)")
        if acc_f is not None and acc_f < 0: raise ValueError("accuracy는 음수일 수 없음")

        # DB 저장을 위한 데이터 준비
        data_tuple = (user_id, lat_f, lon_f, acc_f, lat_f, lon_f, acc_f) # INSERT용 + UPDATE용

    except (ValueError, TypeError) as ve:
        return jsonify({"code": 400, "success": False, "msg": f"입력값 오류: {ve}"}), 400

    # 데이터베이스에 저장 또는 업데이트 (UPSERT)
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn: return jsonify({"code": 500, "success": False, "msg": "DB 연결 실패"}), 500
        cursor = conn.cursor()

        # MySQL의 INSERT ... ON DUPLICATE KEY UPDATE 구문 사용
        # user_id (기본 키)가 이미 존재하면 UPDATE 실행, 없으면 INSERT 실행
        # updated_at 컬럼은 ON UPDATE CURRENT_TIMESTAMP 옵션으로 자동 갱신됨
        sql = """
            INSERT INTO location_logs (user_id, latitude, longitude, accuracy)
            VALUES (%s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
                latitude = VALUES(latitude),
                longitude = VALUES(longitude),
                accuracy = VALUES(accuracy)
                -- updated_at 컬럼은 자동으로 갱신됨
        """
        cursor.execute(sql, (user_id, lat_f, lon_f, acc_f)) # INSERT 부분의 값만 전달
        conn.commit() # 변경사항 최종 저장

        return jsonify({
            "code": 200, # 생성 또는 업데이트 모두 OK
            "success": True,
            "msg": f"사용자 {user_id}의 위치 정보가 성공적으로 저장/업데이트되었습니다."
            # "affectedRows": rowcount # 참고용으로 추가 가능
        }), 200

    except mysql.connector.Error as db_err:
        print(f"MySQL UPSERT 오류 [POST /location-logs]: {db_err}")
        # Foreign Key 오류 등 발생 가능 (users 테이블에 해당 user_id가 없는 경우)
        if db_err.errno == 1452:
             return jsonify({"code": 400, "success": False, "msg": "유효하지 않은 사용자 ID 입니다."}), 400
        return jsonify({"code": 500, "success": False, "msg": "DB 처리 오류"}), 500
    except Exception as e:
        print(f"Upsert location log 오류: {e}")
        return jsonify({"code": 500, "success": False, "msg": "서버 내부 오류"}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception as e: print(f"Location log 커서 닫기 오류: {e}")
        if conn and conn.is_connected():
            try: conn.close(); print("DB connection (location log) closed.")
            except Exception as e: print(f"DB 연결(location log) 닫기 오류: {e}")

# --- Cloud Functions 진입점 함수 ---
def main(request_obj): # Flask의 request와 구분하기 위해 request_obj로 변경
    """Cloud Functions HTTP 트리거를 위한 진입점 함수."""
    with app.request_context(request_obj.environ):
        # 정의된 유일한 라우트인 '/api/location-logs' (POST) 요청 처리
        return app.full_dispatch_request()