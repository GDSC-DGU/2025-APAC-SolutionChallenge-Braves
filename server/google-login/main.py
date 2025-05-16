import os
import json
import jwt
import datetime
import mysql.connector
import secrets
from flask import Flask, request, jsonify
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests

app = Flask(__name__)

# --- Environment Variable Setup ---
db_host = os.environ.get("CLOUD_SQL_HOST")
db_user = os.environ.get("CLOUD_SQL_USER")
db_password = os.environ.get("CLOUD_SQL_PASSWORD")
db_name = os.environ.get("CLOUD_SQL_DATABASE") 

# JWT Settings
JWT_SECRET = os.environ.get("JWT_SECRET") 
JWT_ALGORITHM = "HS256"
JWT_EXPIRATION_SECONDS = 3600  # 1 hour (access token)
# Refresh token expiration time (get from environment variable or use default 30 days)
JWT_REFRESH_EXPIRATION_DAYS = int(os.environ.get("JWT_REFRESH_EXPIRATION_DAYS", 30))

# Google OAuth 2.0 Web Client ID (Required)
GOOGLE_WEB_CLIENT_ID = os.environ.get("GOOGLE_WEB_CLIENT_ID")

# --- Database Connection ---
def get_db_connection():
    """Function to connect to Cloud SQL or local DB"""
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

# --- Token Generation ---
def generate_access_token(user_id):
    """Generate JWT access token based on user ID"""
    payload = {
        'userId': user_id,
        'type': 'access', 
        'exp': datetime.datetime.utcnow() + datetime.timedelta(seconds=JWT_EXPIRATION_SECONDS)
    }
    secret = os.environ.get("JWT_SECRET")
    if not secret:
        raise ValueError("JWT_SECRET environment variable is not set.")
    return jwt.encode(payload, secret, JWT_ALGORITHM)

def generate_refresh_token():
    """Generate refresh token with a secure random string"""
    return secrets.token_hex(32) 

# --- API Routes ---

@app.route('/api/auth/google', methods=['POST'])
def google_login_handler():
    """Handle Google social login and issue tokens (Access + Refresh)"""
    received_id_token = request.json.get('idToken')
    if not received_id_token:
        return jsonify({"code": 400, "success": False, "msg": "ID token is missing."}), 400

    if not GOOGLE_WEB_CLIENT_ID or GOOGLE_WEB_CLIENT_ID == "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com":
         print("CRITICAL: GOOGLE_WEB_CLIENT_ID environment variable is not set correctly.")
         return jsonify({"code": 500, "success": False, "msg": "Server configuration error. (Client ID missing)"}), 500

    conn = None
    cursor = None
    try:
        # 1. Verify Google ID token
        print(f"Verifying ID token (first 10 chars): {received_id_token[:10]}...")
        id_info = google_id_token.verify_oauth2_token(
            received_id_token,
            google_requests.Request(),
            GOOGLE_WEB_CLIENT_ID
        )
        print("ID token verified successfully.")

        social_id = id_info.get('sub')
        email = id_info.get('email')
        username = id_info.get('name')
        profile_image = id_info.get('picture') 

        if not social_id:
             raise ValueError('ID token missing sub claim (user ID).')

        if not email:
            print(f"Warning: Email not provided by Google for social_id {social_id}")
            email = f"user_{social_id}@example.com" 
        if not username:
            print(f"Warning: Username (name) not provided by Google for social_id {social_id}")
            username = "User" 

        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "success": False, "msg": "Failed to connect to the database."}), 500

        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT id, email, username, profile_image FROM users WHERE social_id = %s", (social_id,))
        existing_user = cursor.fetchone()
        user_id = None

        if existing_user:
            user_id = existing_user['id']
            update_fields = {}
            if existing_user.get('email') != email: update_fields['email'] = email
            if existing_user.get('username') != username: update_fields['username'] = username
            if existing_user.get('profile_image') != profile_image: update_fields['profile_image'] = profile_image

            if update_fields:
                print(f"Updating user info for userId: {user_id}, Fields: {list(update_fields.keys())}")
                set_clause = ", ".join([f"{field} = %s" for field in update_fields])
                sql = f"UPDATE users SET {set_clause}, updated_at = NOW() WHERE id = %s"
                params = list(update_fields.values()) + [user_id]
                cursor.execute(sql, tuple(params))
                existing_user.update(update_fields)

        else:
            print(f"Creating new user for social_id: {social_id}")
            cursor.execute(
                """INSERT INTO users
                   (social_id, email, username, profile_image, created_at, updated_at)
                   VALUES (%s, %s, %s, %s, NOW(), NOW())""",
                (social_id, email, username, profile_image)
            )
            user_id = cursor.lastrowid
            print(f"New user created with userId: {user_id}")
            existing_user = {'id': user_id, 'email': email, 'username': username, 'profile_image': profile_image}


        # 2. Prepare user info for response
        final_user_info = {
            "userId": user_id,
            "email": existing_user.get('email'),
            "username": existing_user.get('username'),
            "profileImage": existing_user.get('profile_image') # Use profileImage key
        }

        # 3. Issue tokens (Access + Refresh)
        access_token = generate_access_token(user_id)
        refresh_token_string = generate_refresh_token()
        refresh_expires_at = datetime.datetime.utcnow() + datetime.timedelta(days=JWT_REFRESH_EXPIRATION_DAYS)

        # 4. Save refresh token to DB
        cursor.execute(
            """INSERT INTO refresh_tokens
               (user_id, token, expires_at, created_at)
               VALUES (%s, %s, %s, NOW())""",
            (user_id, refresh_token_string, refresh_expires_at)
        )

        conn.commit() 
        print(f"Tokens issued and refresh token stored for userId: {user_id}")

        response_data = {
            "code": 200,
            "success": True,
            "msg": "Login successful and tokens issued.",
            "data": {
                "token": {
                    "accessToken": access_token,
                    "refreshToken": refresh_token_string,
                    "tokenType": "Bearer",
                    "expiresIn": JWT_EXPIRATION_SECONDS, # Access token expiration time (seconds)
                },
                "user": final_user_info # Use final user info
            }
        }
        return jsonify(response_data), 200

    except ValueError as e:
        print(f"Value Error or Token Verification Failed: {e}")
        return jsonify({"code": 401, "success": False, "msg": f"An error occurred during authentication processing."}), 401
    except mysql.connector.Error as db_err:
        print(f"DB processing error: {db_err}")
        if conn and conn.is_connected():
             try: conn.rollback() 
             except Exception as roll_err: print(f"Rollback failed: {roll_err}")
        return jsonify({"code": 500, "success": False, "msg": f"Error during database processing"}), 500
    except Exception as e:
        print(f"Unexpected error during Google login processing: {type(e).__name__} - {e}")
        return jsonify({"code": 500, "success": False, "msg": f"An internal server error occurred."}), 500
    finally:
        # Close cursor and connection
        if cursor:
            try: cursor.close()
            except Exception as cursor_err: print(f"Cursor closing error: {cursor_err}")
        if conn and conn.is_connected():
            try:
                conn.close()
                print("DB connection closed.")
            except Exception as conn_err: print(f"DB connection closing error: {conn_err}")


@app.route('/api/auth/refresh', methods=['POST'])
def refresh_token_handler():
    """Issue new access token using refresh token (applying Refresh Token Rotation)"""
    received_refresh_token = request.json.get('refreshToken')
    if not received_refresh_token:
        return jsonify({"code": 400, "success": False, "msg": "Refresh token is missing."}), 400

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "success": False, "msg": "Database connection failed"}), 500

        cursor = conn.cursor(dictionary=True)

        # 1. Retrieve and validate refresh token from DB 
        cursor.execute(
            """SELECT id, user_id, expires_at, revoked
               FROM refresh_tokens
               WHERE token = %s""",
            (received_refresh_token,)
        )
        token_info = cursor.fetchone()

        validation_error_msg = None
        if not token_info:
            validation_error_msg = "Refresh token not found."
            print(f"Refresh token not found: {received_refresh_token[:10]}...")
        elif token_info['revoked']:
            validation_error_msg = "Refresh token has already been used or revoked."
            print(f"Refresh token already revoked: {token_info['id']}")
        elif token_info['expires_at'].replace(tzinfo=None) < datetime.datetime.utcnow():
            validation_error_msg = "Expired refresh token."
            print(f"Refresh token expired: {token_info['id']}")

        if validation_error_msg:
            return jsonify({"code": 401, "success": False, "msg": validation_error_msg}), 401

        user_id = token_info['user_id']
        old_token_id = token_info['id']

        # 2. Issue new tokens (Access + Refresh)
        new_access_token = generate_access_token(user_id)
        new_refresh_token_string = generate_refresh_token()
        new_refresh_expires_at = datetime.datetime.utcnow() + datetime.timedelta(days=JWT_REFRESH_EXPIRATION_DAYS)

        # 3. Revoke old refresh token and save new refresh token (Rotation)
        cursor.execute(
            "UPDATE refresh_tokens SET revoked = TRUE WHERE id = %s",
            (old_token_id,)
        )
        cursor.execute(
            """INSERT INTO refresh_tokens
               (user_id, token, expires_at, created_at)
               VALUES (%s, %s, %s, NOW())""",
            (user_id, new_refresh_token_string, new_refresh_expires_at)
        )
        conn.commit() 
        print(f"Refreshed tokens for userId: {user_id}. Old refreshTokenId: {old_token_id} revoked.")

        response_data = {
            "code": 200,
            "success": True,
            "msg": "Access token refreshed successfully.",
            "data": {
                "token": { 
                    "accessToken": new_access_token,
                    "refreshToken": new_refresh_token_string, # Return new refresh token
                    "tokenType": "Bearer",
                    "expiresIn": JWT_EXPIRATION_SECONDS
                }
            }
        }
        return jsonify(response_data), 200

    except mysql.connector.Error as db_err:
        print(f"DB processing error (refresh): {db_err}")
        if conn and conn.is_connected():
            try: conn.rollback()
            except Exception as roll_err: print(f"Rollback failed: {roll_err}")
        return jsonify({"code": 500, "success": False, "msg": f"Error during database processing"}), 500
    except ValueError as e: 
        print(f"Value Error during token generation (refresh): {e}")
        return jsonify({"code": 500, "success": False, "msg": f"Server configuration error during token generation."}), 500
    except Exception as e:
        print(f"Unexpected error during token refresh processing: {type(e).__name__} - {e}")
        return jsonify({"code": 500, "success": False, "msg": f"An internal server error occurred."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception as cursor_err: print(f"Cursor closing error: {cursor_err}")
        if conn and conn.is_connected():
            try:
                conn.close()
                print("DB connection closed.")
            except Exception as conn_err: print(f"DB connection closing error: {conn_err}")


@app.route('/api/auth/logout', methods=['POST'])
def logout_handler():
    """Invalidate refresh token to handle logout"""
    received_refresh_token = request.json.get('refreshToken')
    if not received_refresh_token:
        return jsonify({"code": 400, "success": False, "msg": "Refresh token is missing."}), 400

    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "success": False, "msg": "Database connection failed"}), 500

        cursor = conn.cursor()

        # Find and invalidate (revoked=TRUE) the refresh token
        # Handle even if token is already revoked or non-existent without error (idempotency)
        cursor.execute(
            "UPDATE refresh_tokens SET revoked = TRUE WHERE token = %s AND revoked = FALSE",
            (received_refresh_token,)
        )

        rows_affected = cursor.rowcount 
        conn.commit()

        if rows_affected > 0:
            print(f"Logout successful, revoked refresh token: {received_refresh_token[:10]}...")
        else:
             print(f"Logout attempt: Refresh token not found or already revoked: {received_refresh_token[:10]}...")

        return jsonify({"code": 200, "success": True, "msg": "Logout processed."}), 200

    except mysql.connector.Error as db_err:
        print(f"DB processing error (logout): {db_err}")
        if conn and conn.is_connected():
             try: conn.rollback()
             except Exception as roll_err: print(f"Rollback failed: {roll_err}")
        return jsonify({"code": 500, "success": False, "msg": f"Error during database processing"}), 500
    except Exception as e:
        print(f"Unexpected error during logout processing: {type(e).__name__} - {e}")
        return jsonify({"code": 500, "success": False, "msg": f"An internal server error occurred."}), 500
    finally:
        if cursor:
            try: cursor.close()
            except Exception as cursor_err: print(f"Cursor closing error: {cursor_err}")
        if conn and conn.is_connected():
            try:
                conn.close()
                print("DB connection closed.")
            except Exception as conn_err: print(f"DB connection closing error: {conn_err}")

# --- Cloud Functions Entry Point Function ---
def main(request):
     with app.request_context(request.environ):
          return app.full_dispatch_request() 