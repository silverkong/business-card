import { ethers } from "hardhat";
import { Signer } from "ethers";
import { expect } from "chai";
import { BusinessCardNFT } from "../typechain-types";

describe("BusinessCardNFT", () => {
  let businessCardNFT: BusinessCardNFT;
  let owner: Signer;
  let addressToSend: Signer;

  before("Deploy Business Card", async () => {
    const businessCardNFTFactory = await ethers.getContractFactory(
      "BusinessCardNFT"
    );
    businessCardNFT =
      (await businessCardNFTFactory.deploy()) as BusinessCardNFT;
    [owner, addressToSend] = await ethers.getSigners();
  });

  describe("Register Business Card Info", () => {
    it("Should Register Business Card Info", async () => {
      await businessCardNFT
        .connect(owner)
        .resgisterBusinessCardInfo("Eunbeen", "jungeb325@gmail.com");
      const businessCardInfo = await businessCardNFT.getBusinessCardInfo(
        await owner.getAddress()
      );

      expect(businessCardInfo.name).to.equal("Eunbeen");
    });
  });

  describe("Minting Business Card", () => {
    // 101ms
    it("Should Mint New BusinessCardNFT", async () => {
      await businessCardNFT
        .connect(owner)
        .mintBusinessCard(
          "ipfs://QmUgPxgUqXD2kTs8dpN1rXq72j2D31mqcFphurhuERKpgE",
          { value: ethers.parseEther("0.01") }
        );

      expect(
        await businessCardNFT.balanceOf(await owner.getAddress())
      ).to.equal(10);
    });
  });

  describe("Transfer Business Card", () => {
    it("Should Transfer Business Card", async () => {
      await businessCardNFT
        .connect(owner)
        .transferBusinessCard(await addressToSend.getAddress());

      expect(
        await businessCardNFT.balanceOf(await addressToSend.getAddress())
      ).to.equal(1);

      expect(
        await businessCardNFT.balanceOf(await owner.getAddress())
      ).to.equal(9);

      expect(
        await businessCardNFT.getAmountOfTokenOwnedByIssuer(
          await owner.getAddress()
        )
      ).to.equal(9);
    });
  });
});
