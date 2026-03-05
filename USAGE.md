# Qwen 2.5 모델 사용 가이드

이 문서는 Ollama를 통해 Qwen 2.5 모델을 내려받고, 실제로 번역/대화 기능을 활용하는 방법을 정리합니다.
---

## 1. Ollama 서비스 관리

### 1.1 서버 시작
```bash
# 포그라운드에서 실행 (로그 보면서 테스트할 때 유용)
ollama serve

# 백그라운드에서 실행 (daemon 모드)
ollama serve &

# 또는 macOS라면 자동 시작
# brew services start ollama
```

### 1.2 서버 상태 확인
```bash
# 실행 중인 모델/컨테이너 확인
ollama ps

# 프로세스 직접 확인
ps aux | grep ollama

# 포트 확인 (기본값: 11434)
lsof -i :11434
```

### 1.3 서버 종료
```bash
# 가장 간단한 방법: 프로세스 종료
kill $(pgrep -f 'ollama serve')

# 또는 더 강하게
pkill -f ollama

# macOS라면
brew services stop ollama

# 또는 활성 모델을 모두 언로드한 후 자동 종료 대기
ollama list              # 모델 확인
ollama ps                # 활성 상태 확인 (없으면 자동 종료됨)
```

### 1.4 서버 로그 확인
```bash
# macOS: launchd 로그 확인 (실시간)
log stream --predicate 'process == "ollama"'

# macOS: 서비스 상태 확인
brew services list

# 프로세스 직접 확인
ps aux | grep ollama
```

## 2. 모델 목록 및 상태 확인

### 2.1 설치된 모델 확인
```bash
ollama list

# 예상 출력:
# NAME           ID              SIZE    MODIFIED
# qwen2.5:7b     abc1234...      4.7GB   2분 전
# llama2:13b     def5678...      7.4GB   1개월 전
```

### 2.2 모델 다운로드
```bash
# qwen2.5의 다른 사이즈 받기
ollama pull qwen2.5:3b   # 더 작고 빠름 (약 2GB)
ollama pull qwen2.5:7b   # 기본값 (약 4.7GB)
ollama pull qwen2.5:14b  # 더 큼, 더 정확함 (약 8GB)
```

### 2.3 모델 삭제
```bash
# 특정 모델 삭제
ollama rm qwen2.5:7b

# 여러 모델 한 번에
ollama rm qwen2.5:3b qwen2.5:14b

# 디스크 공간 확인 후 삭제
du -sh ~/.ollama/models/  # 현재 사용 중인 디스크 공간
```

## 3. 커맨드라인에서 사용

### 3.1 한 번만 실행
```bash
ollama run qwen2.5:7b "안녕하세요를 영어로 번역해주세요"
```

### 3.2 인터랙티브 모드 (대화 계속)
```bash
ollama run qwen2.5:7b
# >>> 안녕하세요를 영어로 번역해주세요
# Hello. (또는 "Hello there." 등)
# >>> /bye  # 또는 Ctrl+D로 종료
```

### 3.3 파일 번역 (Bash)
```bash
ollama run qwen2.5:7b "$(< prompt_kr.txt) 이것을 영어로 번역해줘" > prompt_en.txt
```

### 3.4 여러 모델 순차적으로 실행
```bash
# 모델 1 (7B) 사용
ollama run qwen2.5:7b "빠른 번역이 필요합니다"

# 모델 2 (14B) 사용 - 더 정확하게
ollama run qwen2.5:14b "정확한 번역이 필요합니다"

# 여러 모델 동시 실행 (각각 다른 터미널에서)
# 터미널 1:
ollama run qwen2.5:7b

# 터미널 2:
ollama run qwen2.5:14b
```

### 3.5 모델 실행 중 언로드 (메모리 해제)
```bash
# 현재 로드된 모델 확인
ollama ps

# 특정 모델 언로드
# (새로운 모델을 run하면 자동으로 이전 모델은 언로드됨)
ollama ps  # 없으면 메모리가 자유로워짐
```

## 4. Python API 사용

### 패키지 설치
```bash
pip install ollama
```

### 기본 예제
```python
import ollama

resp = ollama.chat(model='qwen2.5:7b', messages=[
    {'role': 'user', 'content': 'Translate 안녕하세요 to English.'}
])
print(resp['message']['content'])
```

### 번역 함수
```python
def translate_ko_to_en(text: str) -> str:
    resp = ollama.chat(
        model='qwen2.5:7b',
        messages=[
            {'role': 'system', 'content': 'You are a translator. Translate Korean to English.'},
            {'role': 'user', 'content': text}
        ]
    )
    return resp['message']['content']

# 테스트
result = translate_ko_to_en('사용자 인증 기능을 구현해주세요')
print(result)
```

### 여러 모델 비교 (Python)
```python
import ollama

def compare_models(text):
    models = ['qwen2.5:7b', 'qwen2.5:14b']
    for model in models:
        resp = ollama.chat(
            model=model,
            messages=[{'role': 'user', 'content': text}]
        )
        print(f"{model}:")
        print(resp['message']['content'])
        print("-" * 50)

compare_models("Design a Python function for user authentication")
```

### 파일 번역 스크립트 예제
`translate.py` 파일이 `setup_qwen.sh`에 의해 생성됩니다. 사용법:
```bash
python3 translate.py input_kr.txt output_en.txt
```

## 5. 성능 최적화 및 팁

### 5.1 메모리 관리
```bash
# 메모리 부족 시 작은 모델 사용
ollama run qwen2.5:3b

# GPU 활용 (자동 감지)
# macOS: Apple Silicon 자동 활용
# Linux: NVIDIA GPU 설정 (ollama pull 후 자동)

# 메모리 상태 확인
free -h  # Linux
vm_stat  # macOS
```

### 5.2 응답 속도 향상
```bash
# 모델 캐싱 활용 (두 번째 실행은 빠름)
ollama run qwen2.5:7b "첫 번째 쿼리"
ollama run qwen2.5:7b "두 번째 쿼리"

# Python에서 연결 재사용 (권장)
client = ollama.Client(host='http://localhost:11434')
# 여러 요청에 재사용
```

### 5.3 용량 줄이기
```bash
# 더 작은 모델 다운로드
ollama pull qwen2.5:3b       # 2GB
ollama pull mistral:7b       # 3.8GB (더 빠름)

# 불필요한 모델 정리
ollama rm qwen2.5:14b
ollama rm qwen2.5:7b
```

## 6. 문제 해결
- **다운로드 오류**: 안정적인 네트워크 확인, `ollama pull qwen2.5:7b` 재시도
- **"connection refused"**: `ollama ps` 확인 후 `ollama serve &` 실행
- **"out of memory"**: 더 작은 모델(`qwen2.5:3b`) 사용
- **Python 연결 실패**: `ollama ps`로 서버 상태 확인, `http://localhost:11434` 접근 가능 확인
- **느린 응답**: 첫 실행은 느릴 수 있음 (모델 로드 시간), 또는 GPU 활용 확인

## 7. 추가 팁
- 시스템 프롬프트를 조절하면 번역 스타일을 지정할 수 있습니다.
- 번역 후 결과를 재검토하고, 필요한 경우 후처리하세요.
- 정확한 번역이 필요하면 `qwen2.5:14b` 사용 (메모리 충분할 때)
- 빠른 응답이 필요하면 `qwen2.5:3b` 또는 `mistral:7b` 사용
