# Business Card NFT

## 명함 NFT User Flow

1. 명함 정보 작성
2. 명함 민팅
   - 명함은 한 번 민팅 시 10개씩 생성
3. 명함 전송
   - 유저는 해당 명함을 한 번만 받을 수 있음
   - 소유자는 명함의 갯수가 0개일 경우 다시 민팅해야 함

### 주의사항

- 명함 정보, 명함 민팅은 컨트랙트 소유자만 가능

## 배포한 컨트랙트 트랜잭션 확인

배포한 컨트랙트를 확인하시려면 [여기](https://sepolia.etherscan.io/address/0x0ebc4ca2a27297882163a760b5a095373793beeb)를 클릭

## `.env` 파일 생성

직접 실행을 위해 `.env` 파일 생성 후 하단과 같이 작성

```
METAMASK_PRIVATE_KEY=본인의 메타마스크 Private Key
SEPOLIA_API_URL=Alchemy에서 발급받은 sepolia network의 api url
```
