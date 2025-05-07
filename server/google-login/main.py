import os
import json
import jwt
import datetime
import mysql.connector
import secrets
from flask import Flask, request, jsonify

# Import google-auth library
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests

app = Flask(__name__)

# --- Environment Variable Setup ---
# Needs to be set in Cloud Run environment variables or local .env file, etc.
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
            port=3306 # Default, but specified
        )
        # Settings that might be needed when considering Korean time zone (optional)
        # conn.cursor().execute("SET time_zone = '+9:00'")
        return conn
    except mysql.connector.Error as err:
        print(f"MySQL connection error: {err}")
        # Enhance error logging on connection failure
        # import logging
        # logging.error(f"MySQL Connection Error: {err}", exc_info=True)
        return None

# --- Token Generation ---
def generate_access_token(user_id):
    """Generate JWT access token based on user ID"""
    payload = {
        'userId': user_id,
        'type': 'access', # Specify token type (optional)
        'exp': datetime.datetime.utcnow() + datetime.timedelta(seconds=JWT_EXPIRATION_SECONDS)
    }
    # Modified to get JWT_SECRET from environment variable
    secret = os.environ.get("JWT_SECRET")
    if not secret:
        raise ValueError("JWT_SECRET environment variable is not set.")
    return jwt.encode(payload, secret, JWT_ALGORITHM)

def generate_refresh_token():
    """Generate refresh token with a secure random string"""
    return secrets.token_hex(32) # Generate a 64-character hexadecimal string

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
        # In case email, name are not in Google response
        email = id_info.get('email')
        username = id_info.get('name')
        profile_image = id_info.get('picture') # Get profile image

        if not social_id:
             raise ValueError('ID token missing sub claim (user ID).')

        # Handling based on DB constraints if email, username are null
        # If email, username columns in users table are NOT NULL, then default value or error handling
        if not email:
            # If email is required, handle error or assign default value
            print(f"Warning: Email not provided by Google for social_id {social_id}")
            # return jsonify({"code": 400, "success": False, "msg": "Email information is required for Google account."}), 400
            email = f"user_{social_id}@example.com" # Temporary email (could be problematic if DB has unique constraint)
        if not username:
            print(f"Warning: Username (name) not provided by Google for social_id {social_id}")
            username = "User" # Default username

        # 2. Database processing (check/create/update user)
        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "success": False, "msg": "Failed to connect to the database."}), 500

        cursor = conn.cursor(dictionary=True)

        # Retrieve user (including id, email, username, profile_image for update comparison)
        cursor.execute("SELECT id, email, username, profile_image FROM users WHERE social_id = %s", (social_id,))
        existing_user = cursor.fetchone()
        user_id = None

        if existing_user:
            user_id = existing_user['id']
            # Check for user info updates (email, username, profile_image)
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
                # Update user info variable after update
                existing_user.update(update_fields)

        else:
            # Create new user (including profile_image)
            print(f"Creating new user for social_id: {social_id}")
            cursor.execute(
                """INSERT INTO users
                   (social_id, email, username, profile_image, created_at, updated_at)
                   VALUES (%s, %s, %s, %s, NOW(), NOW())""",
                (social_id, email, username, profile_image)
            )
            user_id = cursor.lastrowid
            print(f"New user created with userId: {user_id}")
            # Set existing_user with newly created user's info (instead of re-querying DB)
            existing_user = {'id': user_id, 'email': email, 'username': username, 'profile_image': profile_image}


        # Final user info
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
        # (Optional: logic to invalidate existing refresh tokens for the user can be added)
        # cursor.execute("UPDATE refresh_tokens SET revoked = TRUE WHERE user_id = %s AND revoked = FALSE", (user_id,))
        cursor.execute(
            """INSERT INTO refresh_tokens
               (user_id, token, expires_at, created_at)
               VALUES (%s, %s, %s, NOW())""",
            (user_id, refresh_token_string, refresh_expires_at)
        )

        conn.commit() # Commit user creation/update and refresh token storage at once
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
        # When JWT_SECRET is missing or Google token verification fails
        print(f"Value Error or Token Verification Failed: {e}")
        # Display a generic error message to the client
        return jsonify({"code": 401, "success": False, "msg": f"An error occurred during authentication processing."}), 401
    except mysql.connector.Error as db_err:
        print(f"DB processing error: {db_err}")
        if conn and conn.is_connected():
             try: conn.rollback() # Attempt rollback on error
             except Exception as roll_err: print(f"Rollback failed: {roll_err}")
        # Display a generic error message to the client
        return jsonify({"code": 500, "success": False, "msg": f"Error during database processing"}), 500
    except Exception as e:
        # Handle all unexpected errors
        # import traceback
        # print(traceback.format_exc()) # Uncomment for debugging
        print(f"Unexpected error during Google login processing: {type(e).__name__} - {e}")
        return jsonify({"code": 500, "success": False, "msg": f"An internal server error occurred."}), 500
    finally:
        # Close DB connection and cursor
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

        # 1. Retrieve and validate refresh token from DB (check expiration and revocation simultaneously)
        # UTC time comparison caution: DB server and App server time zones might differ.
        # If DB is set to UTC and App server also operates on UTC basis, the comparison below is possible.
        # Safest method is to compare directly in the DB query: ... AND expires_at > NOW() AND revoked = FALSE
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
            # Security enhancement: If a revoked token is used, revoke all tokens for that user? (optional)
            # cursor.execute("UPDATE refresh_tokens SET revoked = TRUE WHERE user_id = %s", (token_info['user_id'],))
            # conn.commit()
        # Ensure timezone consistency when comparing DB time (expires_at) and App server time (utcnow())
        elif token_info['expires_at'].replace(tzinfo=None) < datetime.datetime.utcnow():
            validation_error_msg = "Expired refresh token."
            print(f"Refresh token expired: {token_info['id']}")
            # Consider adding logic to automatically delete expired tokens (scheduler, etc.)

        if validation_error_msg:
            return jsonify({"code": 401, "success": False, "msg": validation_error_msg}), 401

        user_id = token_info['user_id']
        old_token_id = token_info['id']

        # 2. Issue new tokens (Access + Refresh)
        new_access_token = generate_access_token(user_id)
        new_refresh_token_string = generate_refresh_token()
        new_refresh_expires_at = datetime.datetime.utcnow() + datetime.timedelta(days=JWT_REFRESH_EXPIRATION_DAYS)

        # 3. Revoke old refresh token and save new refresh token (Rotation)
        # Start transaction (if needed - MySQL Connector/Python is not autocommit=False by default)
        # conn.start_transaction() # Use explicit transaction if necessary

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
        conn.commit() # Commit changes
        print(f"Refreshed tokens for userId: {user_id}. Old refreshTokenId: {old_token_id} revoked.")

        response_data = {
            "code": 200,
            "success": True,
            "msg": "Access token refreshed successfully.",
            "data": {
                "token": { # Use token object for API specification consistency
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
    except ValueError as e: # If JWT_SECRET is missing in generate_access_token
        print(f"Value Error during token generation (refresh): {e}")
        return jsonify({"code": 500, "success": False, "msg": f"Server configuration error during token generation."}), 500
    except Exception as e:
        # import traceback
        # print(traceback.format_exc()) # Uncomment for debugging
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

        rows_affected = cursor.rowcount # Check number of affected rows (optional logging)
        conn.commit()

        if rows_affected > 0:
            print(f"Logout successful, revoked refresh token: {received_refresh_token[:10]}...")
        else:
             print(f"Logout attempt: Refresh token not found or already revoked: {received_refresh_token[:10]}...")

        # Always return success response to client (200 or 204)
        # return '', 204 # Success without body
        return jsonify({"code": 200, "success": True, "msg": "Logout processed."}), 200

    except mysql.connector.Error as db_err:
        print(f"DB processing error (logout): {db_err}")
        if conn and conn.is_connected():
             try: conn.rollback()
             except Exception as roll_err: print(f"Rollback failed: {roll_err}")
        return jsonify({"code": 500, "success": False, "msg": f"Error during database processing"}), 500
    except Exception as e:
        # import traceback
        # print(traceback.format_exc()) # Uncomment for debugging
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

# If maintaining the old way:
def main(request):
     with app.request_context(request.environ):
          return app.full_dispatch_request() # Corrected to use Flask's dispatching


# --- Local Development Server Execution ---
if __name__ == '__main__':
    print("="*50)
    print("Starting local development server...")
    print(f"- DB Host: {db_host}")
    print(f"- DB Name: {db_name}")
    print(f"- Access Token Expiry: {JWT_EXPIRATION_SECONDS} seconds")
    print(f"- Refresh Token Expiry: {JWT_REFRESH_EXPIRATION_DAYS} days")

    # Enhanced check for required environment variables
    missing_vars = []
    if not GOOGLE_WEB_CLIENT_ID or GOOGLE_WEB_CLIENT_ID == "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com":
        missing_vars.append("GOOGLE_WEB_CLIENT_ID")
    if not JWT_SECRET or JWT_SECRET == "YOUR_FALLBACK_JWT_SECRET_CHANGE_ME":
        missing_vars.append("JWT_SECRET")
    if not db_host: missing_vars.append("CLOUD_SQL_HOST")
    if not db_user: missing_vars.append("CLOUD_SQL_USER")
    if not db_password: missing_vars.append("CLOUD_SQL_PASSWORD")
    if not db_name: missing_vars.append("CLOUD_SQL_DATABASE")

    if missing_vars:
        print("\n!!! Required environment variables missing or using default values !!!")
        for var in missing_vars:
            print(f"  - {var}")
        print("!!! Some features may not work or be insecure. !!!\n")
    print("="*50)


    port = int(os.environ.get('PORT', 8080))
    # debug=True is for development only, recommend False or remove for actual deployment
    # use_reloader=False prevents double execution that sometimes occurs in debug mode
    app.run(debug=True, host='0.0.0.0', port=port, use_reloader=False)