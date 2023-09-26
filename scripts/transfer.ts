import { ethers } from "hardhat";
import { BusinessCardNFT } from "../typechain-types";
import { join } from "path";
import { readFileSync } from "fs";
import dotenv from "dotenv";
dotenv.config();

// ABI 파일 경로 지정
const abiPath = join(
  __dirname,
  "../artifacts/contracts/BusinessCardNFT.sol/BusinessCardNFT.json"
);

// 파일을 읽어서 JSON으로 파싱
const abiJson = JSON.parse(readFileSync(abiPath, "utf-8"));
const abi = abiJson.abi;

// 배포한 NFT 컨트랙트 주소
const nftContractAddress = "0x0ebC4ca2a27297882163A760b5A095373793bEEb";

// 메인 함수 정의
async function mintmain() {
  // provider 초기화
  const provider = ethers.provider;
  // Metamask Private Key
  const privateKey = process.env.METAMASK_PRIVATE_KEY as string;
  // 전송 받을 주소 : 다른 메타마스크 주소 넣음
  const addressToSend = "0xde364c2001e3c584d58d1b0ae13dcd17828741f1";

  if (!privateKey) {
    console.error("Please set the METAMASK_PRIVATE_KEY environment variable");
    process.exitCode = 1;
  }

  const wallet = new ethers.Wallet(privateKey, provider);

  const contract = new ethers.Contract(
    nftContractAddress,
    abi,
    provider
  ).connect(wallet) as BusinessCardNFT;

  // transfer
  await contract.transferBusinessCard(addressToSend);
  console.log(`BusinessCard Transferred to ${addressToSend}`);
}

mintmain()
  .then(() => (process.exitCode = 0))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
