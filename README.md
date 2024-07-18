# Zig를 사용한 게임 엔진 만들기 프로젝트

- Xfit를 서브모듈로 갖고 있기 때문에  git clone --recursive <https://github.com/xfitgd/zig-game-engine-project-test> 이런식으로 클론하면 다 가져 옵니다.
- 빌드 전 build.zig, zig-game-engine-project/engine.zig의 user setting 부분에서 경로 알맞게 설정해주세요.
- windows 크로스 플랫폼 빌드시 zig build -Dtarget=aarch64-windows(linux) 또는 x86_64-windows(linux)
- Android 쪽은 한번 테스트하고 안해서(Windows쪽 완성되면 할 예정) 버그 있을 겁니다.

개발중인 프로젝트이기 때문에 수시로 업데이트 하겠습니다.
