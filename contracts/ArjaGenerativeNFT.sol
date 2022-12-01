// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";

interface IPlonkVerifier {
    function verifyProof(bytes memory proof, uint256[] memory pubSignals)
        external
        view
        returns (bool);
}

interface IAirdropContract {
    function setInitialTokenId(uint256 _firstNFTID) external returns (uint256);
}

contract ArNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;
    mapping(uint256 => Word) public TokenIdToWord;
    // string baseAnimationURI = "https://arar.nft/animation/";
    IPlonkVerifier verifier;

    struct Word {
        uint16 score;
        uint8 background;
        uint8 effect;
        uint8 body;
        uint8 eyes;
        uint8 decoration;
        uint8 ball;
        bool isRevealed;
    }

    constructor() ERC721("NFT", "ARAR") {}

    function setVerifier(address _verifier) public onlyOwner {
        verifier = IPlonkVerifier(_verifier);
    }

    function batchMint(bytes calldata proof, uint256[] calldata pubSignals) external onlyOwner {
        require(
            verifier.verifyProof(proof, pubSignals),
            "Proof verification failed"
        );
        for (uint i = 0; i < pubSignals.length; i++) {
            address to = address(uint160(pubSignals[i]));
            uint256 tokenId = totalSupply() + 1;
            // TokenIdToWord[tokenId] = Word(0, 0, 0, 0, 0 ,0, 0, false);
            _safeMint(to, tokenId);
        }
    }

    function randomNum(
        uint256 _mod,
        uint256 _seed,
        uint256 _salt
    ) public view returns (uint256) {
        uint256 num = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, msg.sender, _seed, _salt)
            )
        ) % _mod;
        return num;
    }

    function setWord(
        uint256 tokenId,
        uint16 score,
        uint8 background,
        uint8 effect,
        uint8 body,
        uint8 eyes,
        uint8 decoration,
        uint8 ball
    ) external onlyOwner {
        require(!TokenIdToWord[tokenId].isRevealed, "Already revealed");
        TokenIdToWord[tokenId] = Word(score, background, effect, body, eyes, decoration, ball, true);
    }

    function buildImage(uint256 _tokenId) private view returns (string memory) {
        Word memory currentWord = TokenIdToWord[_tokenId];
        // string memory random = randomNum(361, 3, 3).toString();
        return
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<svg width="500" height="500" xmlns="http://www.w3.org/2000/svg">',
                        '<rect height="500" width="500" y="0" x="0" />',
                        '<text font-size="18" y="10%" x="50%" text-anchor="middle" fill="hsl(0,0%,100%)">',
                            currentWord.score.toString(),
                        "</text>",
                        getImageDetail(_tokenId),
                        "</svg>"
                    )
                )
            );
    }

    function getImageDetail(uint256 _tokenId) public view returns (string memory) {
        Word memory currentWord = TokenIdToWord[_tokenId];
        return string(abi.encodePacked(
            '<text font-size="18" y="20%" x="50%" text-anchor="middle" fill="hsl(0,0%,100%)">',
            currentWord.background.toString(),
            "</text>",
            '<text font-size="18" y="30%" x="50%" text-anchor="middle" fill="hsl(0,0%,100%)">',
            currentWord.effect.toString(),
            "</text>",
            '<text font-size="18" y="40%" x="50%" text-anchor="middle" fill="hsl(0,0%,100%)">',
            currentWord.body.toString(),
            "</text>",
            '<text font-size="18" y="50%" x="50%" text-anchor="middle" fill="hsl(0,0%,100%)">',
            currentWord.eyes.toString(),
            "</text>"
            // '<text font-size="18" y="60%" x="50%" text-anchor="middle" fill="hsl(0,0%,100%)">',
            // currentWord.decoration.toString(),
            // "</text>",
            // '<text font-size="18" y="70%" x="50%" text-anchor="middle" fill="hsl(0,0%,100%)">',
            // currentWord.ball.toString(),
            // "</text>"
        ));
    }

    function getAttributes(uint256 _tokenId) public view returns (string memory) {
        Word memory currentWord = TokenIdToWord[_tokenId];
        return string(abi.encodePacked(
            "[",
                "{\"trait_type\": \"Background\",\"value\":\"", currentWord.background.toString(), "\"}",
                ",{\"trait_type\": \"Effect\",\"value\":\"", currentWord.effect.toString(), "\"}",
                ",{\"trait_type\": \"Body\",\"value\":\"", currentWord.body.toString(), "\"}",
                ",{\"trait_type\": \"Eyes\",\"value\":\"", currentWord.eyes.toString(), "\"}",
                // ",{\"trait_type\": \"Decoration\",\"value\":\"", currentWord.decoration.toString(), "\"}",
                // ",{\"trait_type\": \"Ball\",\"value\":\"", currentWord.ball.toString(), "\"}",
            "]"
        ));
    }

    function buildMetadata(uint256 _tokenId)
        private
        view
        returns (string memory)
    {
        string memory token = Strings.toString(_tokenId);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{ \"name\": \"", name() , " #", token,
                                "\",\"image\": \"",
                                    "data:image/svg+xml;base64,",
                                    buildImage(_tokenId),
                                "\",\"attributes\": ",
                                    getAttributes(_tokenId),
                                // TODO: animation_url
                                // ",\"animation_url\":\"", baseAnimationURI, token, ".html\""
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return buildMetadata(_tokenId);
    }
}
