FROM python:3.11-slim

WORKDIR /usr/src/app
COPY . .

RUN pip install --require-hashes -r base-tooling-requirements.txt
RUN pip install --require-hashes -r requirements.txt
# Install dependencies directly
RUN pip install flask==3.0.2 google-genai==1.5.0 gunicorn==21.2.0

EXPOSE 8080

# Use Gunicorn for production
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]