# language_ai

이 디렉터리는 Ollama와 Qwen 2.5 모델을 이용해 한국어→영어 번역 환경을 구성하는 예제를 담고 있습니다.

### 설치 스크립트
- `setup_qwen.sh`: Ollama 설치, 서버 실행, Qwen 2.5 모델 다운로드 및 Python 패키지/예제 스크립트 생성

### 사용 안내
- `USAGE.md`: 모델 실행 및 번역 예제 정리 문서

### 터미널 환경 설정 (Global CLI Tool)
시스템 전역에서 `translate` 명령어를 바로 사용할 수 있도록 환경 설정을 자동화하는 쉘 스크립트가 포함되어 있습니다.

```bash
# ZSH 설정 파일(~/.zshrc)에 'translate' 명령어 매핑
bash setup_translate.sh

# 현재 터미널에 즉시 적용
source ~/.zshrc
```

#### 번역 CLI 기본 사용법
```bash
translate 안녕하세요, 오늘 날씨가 참 좋습니다.
```

#### 클립보드 복사 모드 (`-c` 또는 `--clipboard`)
명령어 뒤에 붙이면 터미널에 결과가 출력되지 않고, 번역된 텍스트가 즉시 클립보드에 복사(Mac `pbcopy` / 리눅스 `xclip` 자동 대응)됩니다.
```bash
# 직접 텍스트를 입력해서 복사할 때
translate 오늘 커피 한잔 하실래요? -c

# 다른 파일의 내용을 읽어서 번역 후 복사할 때
cat input.txt | translate -c

# 현재 클립보드에 복사되어 있는 문장을 바로 번역해서 덮어씌울 때
translate --clipboard
```
> 스크립트 내부에서 스크립트 실행 위치의 절대 경로를 동적으로 읽어오기 때문에, 다른 서버에서 `git clone`을 받더라도 설정만 한 번 다시 해주면 바로 동작합니다!
