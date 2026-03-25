FROM python:3.11-alpine
WORKDIR /apk
COPY app/build/outputs/apk/debug/app-debug.apk .
EXPOSE 8080
CMD ["python3", "-m", "http.server", "8080"]