import os
import json
import jwt
import datetime
import uuid
import mysql.connector
from flask import Flask, request, jsonify, abort
from functools import wraps
from google.cloud import storage

app = Flask(__name__)

# --- 환경 변수 설정 ---
db_host = os.environ.get("CLOUD_SQL_HOST")
db_user = os.environ.get("CLOUD_SQL_USER")
db_password = os.environ.get("CLOUD_SQL_PASSWORD")
db_name = os.environ.get("CLOUD_SQL_DATABASE")
JWT_SECRET = os.environ.get("JWT_SECRET", "change-this-in-prod") # 실제 키로 변경!
JWT_ALGORITHM = "HS256"
GCS_BUCKET_NAME = os.environ.get("GCS_BUCKET_NAME")

# --- GCS 클라이언트 초기화 ---
try:
    storage_client = storage.Client()
except Exception as e:
    print(f"Error initializing GCS client: {e}")
    storage_client = None

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

# --- 파일 유효성 검사 설정 ---
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
MAX_CONTENT_LENGTH = 10 * 1024 * 1024 

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

app.config['MAX_CONTENT_LENGTH'] = MAX_CONTENT_LENGTH

@app.errorhandler(413)
def request_entity_too_large(error):
    return jsonify({"code": 413, "success": False, "msg": f"이미지 파일 크기 제한 초과 ({MAX_CONTENT_LENGTH / 1024 / 1024:.0f}MB)"}), 413

# --- API 라우트 ---

# === 미션 이미지 업로드/수정 API ===
# POST 또는 PUT 요청 모두 이 함수로 처리 
@app.route('/api/missions/<int:mission_id>/completion-image', methods=['POST', 'PUT'])
@token_required
def upload_or_update_mission_image(current_user_id, mission_id):
    """미션 완료 이미지를 받아 GCS 업로드 및 DB에 공개 URL 저장/수정"""
    user_id = current_user_id
    if 'image_file' not in request.files: return jsonify({"code": 400, "success": False, "msg": "'image_file' 파트 없음"}), 400
    file = request.files['image_file']
    if file.filename == '': return jsonify({"code": 400, "success": False, "msg": "선택된 파일 없음"}), 400
    if not file or not allowed_file(file.filename): return jsonify({"code": 400, "success": False, "msg": f"허용된 이미지 형식 아님 ({', '.join(ALLOWED_EXTENSIONS)})"}), 400
    if not GCS_BUCKET_NAME: print("CRITICAL: GCS_BUCKET_NAME 환경 변수가 설정되지 않았습니다."); return jsonify({"code": 500, "success": False, "msg": "서버 설정 오류 (Bucket name missing)"}), 500
    if not storage_client: print("CRITICAL: GCS Client not initialized."); return jsonify({"code": 500, "success": False, "msg": "서버 설정 오류 (GCS Client)"}), 500

    conn = None; cursor_check = None; cursor_update = None; old_gcs_image_url = None; new_gcs_object_name = None; public_gcs_url = None
    try:
        conn = get_db_connection()
        if not conn: return jsonify({"code": 500, "success": False, "msg": "DB 연결 실패"}), 500

        cursor_check = conn.cursor(dictionary=True)
        sql_check = "SELECT t.user_id, m.completion_image FROM missions m JOIN travels t ON m.travel_id = t.id WHERE m.id = %s"
        cursor_check.execute(sql_check, (mission_id,))
        mission_data = cursor_check.fetchone()
        old_gcs_image_url = mission_data.get('completion_image') if mission_data else None

        if cursor_check:
            try: cursor_check.close()
            except Exception as e: print(f"Check 커서(upload/update) 1차 닫기 오류: {e}")
        cursor_check = None

        if not mission_data: return jsonify({"code": 404, "success": False, "msg": f"Mission ID {mission_id} 없음"}), 404
        if mission_data['user_id'] != user_id: return jsonify({"code": 403, "success": False, "msg": "해당 미션에 접근 권한 없음"}), 403

        # 기존 이미지 GCS에서 삭제 
        if old_gcs_image_url:
            try:
                object_name_to_delete = None
                if old_gcs_image_url.startswith(f"https://storage.googleapis.com/{GCS_BUCKET_NAME}/"):
                    object_name_to_delete = old_gcs_image_url.replace(f"https://storage.googleapis.com/{GCS_BUCKET_NAME}/", "", 1)
                else: 
                    object_name_to_delete = old_gcs_image_url

                if object_name_to_delete:
                     old_blob_to_delete = storage_client.bucket(GCS_BUCKET_NAME).blob(object_name_to_delete)
                     if old_blob_to_delete.exists():
                         old_blob_to_delete.delete()
                         print(f"Old GCS image {object_name_to_delete} deleted for replacement.")
            except Exception as delete_err: print(f"Error deleting old GCS image {old_gcs_image_url}: {delete_err}")

        # 새 이미지 GCS에 업로드
        try:
            file_extension = os.path.splitext(file.filename)[1]
            unique_filename = f"{uuid.uuid4().hex}{file_extension}"
            new_gcs_object_name = f"missions/user-{user_id}/mission-{mission_id}-{unique_filename}"
            bucket = storage_client.bucket(GCS_BUCKET_NAME)
            blob = bucket.blob(new_gcs_object_name)
            print(f"Uploading new file to gs://{GCS_BUCKET_NAME}/{new_gcs_object_name}")
            file.seek(0); blob.upload_from_file(file.stream, content_type=file.content_type)
            print("New file uploaded successfully.")
            public_gcs_url = blob.public_url 

        except Exception as gcs_err: print(f"GCS Upload/MakePublic Error: {gcs_err}"); return jsonify({"code": 500, "success": False, "msg": "이미지 업로드 또는 공개 처리 중 서버 오류 발생"}), 500

        sql_update = "UPDATE missions SET completion_image = %s, updated_at = NOW() WHERE id = %s"
        cursor_update = conn.cursor(); cursor_update.execute(sql_update, (public_gcs_url, mission_id)); conn.commit()

        return jsonify({
            "code": 200, "success": True, "msg": f"미션(ID: {mission_id}) 이미지 업로드/수정 및 저장 성공",
            "filePath": new_gcs_object_name, 
            "fileUrl": public_gcs_url 
        }), 200
    except mysql.connector.Error as db_err: print(f"MySQL 오류 [POST/PUT ...completion-image]: {db_err}"); return jsonify({"code": 500, "success": False, "msg": "DB 처리 오류"}), 500
    except Exception as e: print(f"Upload/Update mission image 오류: {type(e).__name__} - {e}"); return jsonify({"code": 500, "success": False, "msg": "서버 내부 오류"}), 500
    finally:
        if cursor_check:
            try: cursor_check.close()
            except Exception as e: print(f"Check 커서(upload/update) finally 오류: {e}")
        if cursor_update:
            try: cursor_update.close()
            except Exception as e: print(f"Update 커서(upload/update) finally 오류: {e}")
        if conn and conn.is_connected():
            try: conn.close(); print("DB connection (upload/update) closed.")
            except Exception as e: print(f"DB 연결(upload/update) finally 오류: {e}")

# === 미션 완료 이미지 삭제 API ===
@app.route('/api/missions/<int:mission_id>/completion-image', methods=['DELETE'])
@token_required
def delete_completion_image(current_user_id, mission_id):
    """특정 미션의 완료 이미지를 GCS에서 삭제하고 DB에서 경로 제거"""
    user_id = current_user_id
    conn = None; cursor_check = None; cursor_update = None; gcs_object_name_to_delete = None
    try:
        conn = get_db_connection()
        if not conn: return jsonify({"code": 500, "success": False, "msg": "DB 연결 실패"}), 500
        cursor_check = conn.cursor(dictionary=True)
        sql_check = "SELECT t.user_id, m.completion_image FROM missions m JOIN travels t ON m.travel_id = t.id WHERE m.id = %s"
        cursor_check.execute(sql_check, (mission_id,))
        mission_data = cursor_check.fetchone()
        try: cursor_check.close()
        except Exception as e: print(f"Check 커서(삭제) 닫기 오류: {e}"); cursor_check = None

        if not mission_data: return jsonify({"code": 404, "success": False, "msg": f"Mission ID {mission_id} 없음"}), 404
        if mission_data['user_id'] != user_id: return jsonify({"code": 403, "success": False, "msg": "해당 미션에 접근 권한 없음"}), 403
        
        gcs_image_url_to_delete = mission_data.get('completion_image')
        if not gcs_image_url_to_delete: return jsonify({"code": 404, "success": False, "msg": f"미션(ID: {mission_id})에 삭제할 이미지 없음"}), 404
        
        try:
            object_name_to_delete = None
            if gcs_image_url_to_delete.startswith(f"https://storage.googleapis.com/{GCS_BUCKET_NAME}/"):
                object_name_to_delete = gcs_image_url_to_delete.replace(f"https://storage.googleapis.com/{GCS_BUCKET_NAME}/", "", 1)
            else: 
                object_name_to_delete = gcs_image_url_to_delete
            
            if object_name_to_delete:
                bucket = storage_client.bucket(GCS_BUCKET_NAME)
                blob = bucket.blob(object_name_to_delete)
                if blob.exists():
                    blob.delete()
                    print(f"GCS image {object_name_to_delete} deleted.")
                else:
                    print(f"GCS image {object_name_to_delete} not found for deletion.")
            else:
                print(f"Invalid GCS path derived for deletion: {gcs_image_url_to_delete}")
        except Exception as gcs_err:
            print(f"GCS Delete Error for {gcs_object_name_to_delete or gcs_image_url_to_delete}: {gcs_err}")

        sql_update = "UPDATE missions SET completion_image = NULL, updated_at = NOW() WHERE id = %s"
        cursor_update = conn.cursor()
        cursor_update.execute(sql_update, (mission_id,))
        conn.commit()
        return jsonify({"code": 200, "success": True, "msg": f"미션(ID: {mission_id}) 이미지 삭제 성공"}), 200
    except mysql.connector.Error as db_err: print(f"MySQL 오류 [DELETE ...completion-image]: {db_err}"); return jsonify({"code": 500, "success": False, "msg": "DB 처리 오류"}), 500
    except Exception as e: print(f"Delete completion image 오류: {e}"); return jsonify({"code": 500, "success": False, "msg": "서버 내부 오류"}), 500
    finally:
        if cursor_check:
          try: cursor_check.close()
          except Exception as e: print(f"Check 커서(삭제) finally 오류: {e}")
        if cursor_update:
          try: cursor_update.close()
          except Exception as e: print(f"Update 커서(삭제) finally 오류: {e}")
        if conn and conn.is_connected():
          try: conn.close(); print("DB connection (delete) closed.")
          except Exception as e: print(f"DB 연결(삭제) finally 오류: {e}")

# --- Cloud Functions Entry Point Function ---
def main(request_obj):
    """Cloud Functions HTTP 트리거를 위한 진입점 함수."""
    with app.request_context(request_obj.environ):
        return app.full_dispatch_request()