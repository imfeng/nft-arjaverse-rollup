// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
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

contract ArjaGenerativeNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    mapping(uint256 => Word) public TokenIdToWord;
    string baseAnimationURI = "https://arja.nft/animation/";
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

    constructor() ERC721("Arjaverse NFT", "ARJA") {}

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
            TokenIdToWord[tokenId] = Word(0, 0, 0, 0, 0 ,0, 0, false);
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

    function buildImage(uint256 _tokenId) private view returns (string memory) {
        Word memory currentWord = TokenIdToWord[_tokenId];
        string memory random = randomNum(361, 3, 3).toString();
        return
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<svg width="500" height="500" xmlns="http://www.w3.org/2000/svg">',
                        '<rect height="500" width="500" y="0" x="0" />',
                        '<text font-size="18" y="10%" x="50%" text-anchor="middle" fill="hsl(',
                        random,
                        ',100%,80%)">',
                        currentWord.score,
                        "</text>",
                        '<text font-size="18" y="10%" x="50%" text-anchor="middle" fill="hsl(',
                        random,
                        ',100%,80%)">',
                        currentWord.background,
                        "</text>",
                        '<text font-size="18" y="10%" x="50%" text-anchor="middle" fill="hsl(',
                        random,
                        ',100%,80%)">',
                        currentWord.effect,
                        "</text>",
                        '<text font-size="18" y="10%" x="50%" text-anchor="middle" fill="hsl(',
                        random,
                        ',100%,80%)">',
                        currentWord.body,
                        "</text>",
                        '<text font-size="18" y="10%" x="50%" text-anchor="middle" fill="hsl(',
                        random,
                        ',100%,80%)">',
                        currentWord.eyes,
                        "</text>",
                        '<text font-size="18" y="10%" x="50%" text-anchor="middle" fill="hsl(',
                        random,
                        ',100%,80%)">',
                        currentWord.decoration,
                        "</text>",
                        '<text font-size="18" y="10%" x="50%" text-anchor="middle" fill="hsl(',
                        random,
                        ',100%,80%)">',
                        currentWord.ball,
                        "</text>",
                        "</svg>"
                    )
                )
            );
    }

    function buildMetadata(uint256 _tokenId)
        private
        view
        returns (string memory)
    {
        Word memory currentWord = TokenIdToWord[_tokenId];
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{ "name": "', name() , ' #', _tokenId,
                                '","image": "',
                                    "data:image/svg+xml;base64,",
                                    buildImage(_tokenId),
                                '","attributes": ',
                                    "[",
                                        '{"trait_type": "Background",', '"value":"', currentWord.background, '"}',
                                        '{"trait_type": "Effect",', '"value":"', currentWord.effect, '"}',
                                        '{"trait_type": "Body",', '"value":"', currentWord.body, '"}',
                                        '{"trait_type": "Eyes",', '"value":"', currentWord.eyes, '"}',
                                        '{"trait_type": "Decoration",', '"value":"', currentWord.decoration, '"}',
                                        '{"trait_type": "Ball",', '"value":"', currentWord.ball, '"}',
                                    "],",
                                // TODO: animation_url
                                '"animation_url":"', baseAnimationURI, _tokenId, '.html"}'
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
