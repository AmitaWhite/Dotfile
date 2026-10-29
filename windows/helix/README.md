# Windows(파견지) Helix 설정 가이드

회사 Windows PC에서 **가볍게** 쓰기 위한 설정입니다. 편집, 화면 분할과 이동, LSP, 정의로 이동까지만 Helix로 하고, 디버깅, 테스트, DB, MyBatis XML 탐색은 VS Code로 합니다.

- 대상 프로젝트: React(tsx, Vite) + Spring Boot(Java 17, Gradle, Lombok, MyBatis)
- 파일: [config.toml](config.toml), [languages.toml](languages.toml) → `%APPDATA%\helix\`에 둡니다.
- 아래 명령은 전부 **PowerShell**에서 실행합니다. 블록 단위로 복사해서 붙여 넣으면 됩니다.
- 각 단계 끝의 **✅ 확인**이 통과하면 다음 단계로 넘어갑니다. 막히면 그 단계의 에러 메시지를 보면 됩니다.

조각은 세 개뿐입니다.

| 조각 | 역할 | 위치 |
|---|---|---|
| jdtls | Java 분석기 | `%USERPROFILE%\tools\jdtls` |
| JDK 21 | jdtls를 실행하는 엔진 (jdtls 전용) | `%USERPROFILE%\tools\jdk-21` |
| Python | jdtls 시동 스크립트를 돌림 | 이미 있을 수도 있음 |

기존 `JAVA_HOME`(JDK 17)은 **건드리지 않습니다.** 회사 빌드는 계속 17을 씁니다.

---

## 0단계: 설정 파일 넣기 (TS까지)

```powershell
mkdir $env:APPDATA\helix -Force
notepad $env:APPDATA\helix\config.toml
```
[config.toml](config.toml) 내용을 붙여 넣고 저장합니다.

```powershell
notepad $env:APPDATA\helix\languages.toml
```
[languages.toml](languages.toml)에서 **`# ---- 백엔드 (Java)` 줄 위까지만** 붙여 넣고 저장합니다. Java 부분은 4단계가 끝난 뒤에 붙입니다.

✅ 확인: `hx`가 오류 없이 켜지고 gruvbox-material 테마가 보입니다.

## 1단계: TypeScript LSP (이미 했다면 건너뛰기)

```powershell
npm install -g typescript typescript-language-server
hx --health tsx
```
✅ 확인: `typescript-language-server`에 ✓가 뜹니다. 프론트 폴더에서 `.tsx` 파일을 열고 `gd`로 정의 이동이 됩니다.

> `@/...` import에서 `gd`가 안 되면 `tsconfig.json`이나 `tsconfig.app.json`의 `compilerOptions.paths`에 `"@/*": ["src/*"]`가 있는지 확인하세요. `vite.config.ts`에만 있으면 LSP는 그 별칭을 모릅니다.

---

## 2단계: Python 확인

```powershell
python --version
py --version
where.exe python
```
- `python`이 3.9 이상이면 그대로 씁니다.
- `python`은 안 되고 `py`만 되면, 나중에 `languages.toml`의 `command = "python"`을 `"py"`로 바꿉니다.
- `python`을 쳤는데 **Microsoft Store가 열리면** 진짜 Python이 아닙니다. 아래 명령으로 설치된 위치를 찾고, `command`에 **전체 경로**(`/`로 바꿔서)를 씁니다. PATH는 고치지 않아도 됩니다.
  ```powershell
  Get-ChildItem $env:LOCALAPPDATA\Programs\Python -Recurse -Filter python.exe
  ```

✅ 확인: Python 3.9 이상을 실행하는 명령 하나(`python`, `py`, 또는 전체 경로)를 확보합니다.

## 3단계: JDK 21과 jdtls 압축 풀기

1. **JDK 21**: Temurin(adoptium.net)이나 Microsoft Build of OpenJDK에서 **Windows x64 zip**을 받습니다. 설치 프로그램(msi)이 아니라 zip입니다.
2. **jdtls**: `download.eclipse.org/jdtls/milestones/`에서 최신 버전 폴더로 들어가 `jdt-language-server-*.tar.gz`를 받습니다.

받은 파일이 `다운로드` 폴더에 있다고 할 때:

```powershell
mkdir $env:USERPROFILE\tools -Force
Expand-Archive $env:USERPROFILE\Downloads\OpenJDK21*.zip -DestinationPath $env:USERPROFILE\tools
```
zip 파일 이름은 배포처마다 다릅니다(`OpenJDK21U-jdk_x64_windows_hotspot_*.zip`, `microsoft-jdk-21*.zip` 등). 실제 이름에 맞게 고치세요. 압축을 풀면 `jdk-21.0.x+y` 같은 폴더가 생기는데, **이름을 `jdk-21`로 바꿉니다.**

```powershell
Get-ChildItem $env:USERPROFILE\tools
Rename-Item "$env:USERPROFILE\tools\<풀린 폴더 이름>" jdk-21
```

jdtls는 tar.gz입니다. Windows 10 이상에는 `tar`가 기본으로 들어 있습니다.
```powershell
mkdir $env:USERPROFILE\tools\jdtls -Force
tar -xzf (Get-Item $env:USERPROFILE\Downloads\jdt-language-server-*.tar.gz).FullName -C $env:USERPROFILE\tools\jdtls
```

✅ 확인: 아래 두 명령이 모두 성공합니다.
```powershell
& $env:USERPROFILE\tools\jdk-21\bin\java.exe -version
Test-Path $env:USERPROFILE\tools\jdtls\bin\jdtls
```
첫 줄은 `21.x`를 출력하고, 둘째 줄은 `True`를 출력합니다.

## 4단계: Helix 없이 jdtls만 띄워 보기 (가장 중요)

```powershell
$env:JAVA_HOME = "$env:USERPROFILE\tools\jdk-21"
python $env:USERPROFILE\tools\jdtls\bin\jdtls
```
(`python`은 2단계에서 확보한 명령으로 바꿉니다.)

- `$env:`로 바꾼 값은 **이 PowerShell 창에서만** 적용됩니다. 시스템의 JDK 17은 그대로입니다. 끝나면 이 창은 닫습니다.
- **에러 없이 멈춰서 기다리면 성공입니다.** Helix의 요청을 기다리는 상태입니다. `Ctrl+C`로 끕니다.
- Java 버전 얘기가 나오면 `JAVA_HOME` 경로가 틀린 것이고, python을 못 찾는다고 나오면 2단계로 돌아갑니다.

✅ 확인: 에러 없이 대기 상태가 됩니다.

## 5단계: Lombok jar 준비

Gradle 캐시에 이미 있을 가능성이 높습니다.
```powershell
Get-ChildItem $env:USERPROFILE\.gradle\caches\modules-2\files-2.1\org.projectlombok\lombok -Recurse -Filter "lombok-*.jar" | Where-Object Name -notmatch "sources|javadoc"
```
나온 파일 중 하나(되도록 프로젝트 `build.gradle`과 같은 버전)를 **버전 없는 이름으로** 복사합니다.
```powershell
Copy-Item "<위에서 나온 lombok-x.y.z.jar 전체 경로>" $env:USERPROFILE\tools\lombok.jar
```
아무것도 안 나오면 projectlombok.org에서 `lombok.jar`를 받아 같은 위치에 둡니다.

✅ 확인: `Test-Path $env:USERPROFILE\tools\lombok.jar` → `True`

## 6단계: Helix에 Java 연결

먼저 바꿔 넣을 값 두 개를 확인합니다.
```powershell
$env:USERNAME          # <사용자> 자리에 들어갈 이름
$env:JAVA_HOME         # 기존 JDK 17 경로 (시스템 값)
```
> 4단계 창을 아직 열어 두었다면 `JAVA_HOME`이 21로 나옵니다. **새 PowerShell 창**에서 확인하세요.

```powershell
notepad $env:APPDATA\helix\languages.toml
```
[languages.toml](languages.toml)의 **`# ---- 백엔드 (Java)` 아래 부분**을 파일 끝에 붙이고 다음을 고칩니다.
- `<사용자>` 세 군데 → 위에서 확인한 이름
- `<지금 JAVA_HOME 의 JDK 17 경로>` → 위에서 확인한 경로 (`\`를 `/`로 바꿔서)
- `command = "python"` → 2단계에서 확보한 명령 (`py`나 전체 경로일 수도 있음)

✅ 확인:
```powershell
hx --health java
```
`jdtls`에 ✓가 뜹니다.

## 7단계: 프로젝트에서 써 보기

먼저 터미널에서 컴파일이 되는지 봅니다. 이게 되면 jdtls도 거의 됩니다.
```powershell
cd <백엔드 프로젝트 폴더>
.\gradlew compileJava
```
그다음 **`build.gradle`이 있는 폴더에서** Helix를 켭니다.
```powershell
hx src\main\java
```
- **처음 열 때는 프로젝트를 불러오느라 몇 분 걸립니다.** 하단 상태줄에 진행 상황이 보입니다.
- 다 불러온 뒤 클래스 이름 위에서 `gd`가 되면 성공입니다.
- 안 되면 Helix 안에서 `:log-open`으로 로그를 봅니다.

✅ 확인: `gd`로 정의 이동, `space s`로 메서드 목록이 나옵니다. Lombok getter를 쓰는 줄에 빨간 줄이 없습니다.

---

## 자주 쓰는 키

| 하는 일 | 키 |
|---|---|
| 세로 / 가로 분할 | `C-w v` / `C-w s` |
| 분할 창 이동 | `C-w h/j/k/l` |
| 분할 창 닫기 | `C-w q` |
| 파일 찾기 / 전체 grep | `space f` / `space /` |
| 열린 버퍼 목록 | `space b` |
| 정의 / 참조 / 구현으로 이동 | `gd` / `gr` / `gi` |
| 이전 위치로 돌아가기 | `C-o` |
| 파일 안 심볼 / 프로젝트 전체 심볼 | `space s` / `space S` |
| 진단(에러) 목록 | `space d` |
| 이름 바꾸기 / 코드 액션 | `space r` / `space a` |
| 포맷 (직접 실행할 때만) | `:format` |
| 문서 보기 (hover) | `space k` |

## 알려진 한계

- **MyBatis**: Mapper 인터페이스에서 XML 쿼리로 바로 가는 기능은 없습니다. `space /`로 메서드 이름을 grep하거나 VS Code를 씁니다.
- **QueryDSL 및 MapStruct**: 생성 코드(Q클래스 등)를 jdtls가 못 찾으면 그 줄만 빨간 줄이 뜹니다. `.\gradlew compileJava`를 한 번 돌린 뒤 Helix에서 `:lsp-restart`를 실행해 보세요. 그래도 남으면 감수하거나 그 작업만 VS Code로 합니다.
- **포맷**: 팀 표준(ESLint, biome, Prettier 중 무엇인지)이 확인될 때까지 자동 포맷은 꺼 둡니다. `.vscode/settings.json`의 `editor.defaultFormatter`, `package.json`의 `lint-staged` 항목을 보면 팀 표준을 알 수 있습니다.
- **디버깅과 테스트**: VS Code를 씁니다.
