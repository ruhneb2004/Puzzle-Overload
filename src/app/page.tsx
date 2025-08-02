"use client";
import { ethers, keccak256, parseEther, toUtf8Bytes } from "ethers";
import NextImage from "next/image";
import { useEffect, useState } from "react";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import axios from "axios";
import { http, usePublicClient } from "wagmi";
import { toast, ToastContainer } from "react-toastify";
import { useWalletClient } from "wagmi";
import { abi, contractAddr } from "./abi";
import { log } from "console";

export default function Home() {
  const [tiles, setTiles] = useState<string[]>([]);
  const [tileHashes, setTileHashes] = useState<string[]>([]);
  const [answerHash, setAnswerHash] = useState<string>("");
  const [selectedTile, setSelectedTile] = useState<number | null>(null);
  const [image, setImage] = useState<string>("");
  const [level, setLevel] = useState<number>(0);
  const [gameId, setGameId] = useState<number>(1);
  const [joinedHashes, setJoinedHashes] = useState<string>("");
  const { data: walletClient } = useWalletClient();
  const publicClient = usePublicClient();
  const [currentHash, setCurrentHash] = useState<string>(
    "click the button to see current hash"
  );
  const imageSrc = `/api/imageProxy?url=https://picsum.photos/600/400?${Date.now()}`;

  useEffect(() => {
    if (!publicClient) return;
    const unwatchEnterGame = publicClient.watchContractEvent({
      address: contractAddr,
      abi: abi,
      eventName: "PuzzleGame_PlayerEntered",
      onLogs: (log) => {
        console.log("Game entered:", log);
        toast.success(
          "Game entered successfully! Please register your solution."
        );
      },
    });
    return () => {
      unwatchEnterGame();
    };
  }, [publicClient]);

  useEffect(() => {
    if (!publicClient) return;
    const unwatchRegisterGame = publicClient.watchContractEvent({
      address: contractAddr,
      abi: abi,
      eventName: "PuzzleGame_GameRegistered",
      onLogs: (log) => {
        console.log("Game entered:", log);
        toast.success("Game registered successfully! You can now play.");
      },
    });
    return () => {
      unwatchRegisterGame();
    };
  }, [publicClient]);

  useEffect(() => {
    if (!publicClient) return;
    const unwatchRoundCleared = publicClient.watchContractEvent({
      address: contractAddr,
      abi: abi,
      eventName: "PuzzleGame_RoundCleared",
      onLogs: (log) => {
        console.log("Round cleared:", log);
        toast.success("Round cleared successfully! You can now proceed.");
      },
    });
    return () => {
      unwatchRoundCleared();
    };
  }, [publicClient]);

  const enterAndRegisterGame = async () => {
    try {
      const enterGame = await walletClient?.writeContract({
        address: contractAddr,
        abi: abi,
        functionName: "enterGame",
        args: [],
        value: BigInt(parseEther("0.001")),
      });
      await publicClient?.waitForTransactionReceipt({
        hash: enterGame as `0x${string}`,
      });
      const registerGame = await walletClient?.writeContract({
        address: contractAddr,
        abi: abi,
        functionName: "registerGameSolution",
        args: [answerHash],
      });
      await publicClient?.waitForTransactionReceipt({
        hash: registerGame as `0x${string}`,
      });
      console.log("Game entered and registered successfully");
      fetchGameData();
    } catch (error) {
      console.log("Error entering or registering game:", error);
    }
  };
  const regsiterGame = async () => {
    try {
      const registerGame = await walletClient?.writeContract({
        address: contractAddr,
        abi: abi,
        functionName: "registerGameSolution",
        args: [answerHash],
      });
      await publicClient?.waitForTransactionReceipt({
        hash: registerGame as `0x${string}`,
      });
      console.log("Game registered successfully");
      fetchGameData();
    } catch (error) {
      console.log("Error registering game:", error);
    }
  };
  const fetchGameData = async () => {
    console.log(publicClient?.chain.id);
    if (!publicClient) {
      console.log("not inited");
      return;
    }

    const currentGameId = await publicClient?.readContract({
      address: contractAddr,
      abi: abi,
      functionName: "getCurrentGameId",
    });
    console.log(currentGameId);
    console.log("wallet address", walletClient?.account.address);
    setGameId(Number(currentGameId));
    const lvl = await publicClient?.readContract({
      address: contractAddr,
      abi: abi,
      functionName: "playerScores",
      args: [currentGameId, walletClient?.account.address],
    });
    setLevel(Number(lvl));
    console.log("level", lvl);
  };

  useEffect(() => {
    if (walletClient && publicClient) {
      fetchGameData();
    }
  }, [walletClient, publicClient]);

  useEffect(() => {
    splitImage(imageSrc, level + 2, level + 2);
  }, [level]);

  const shuffleImages = (pieces: string[]) => {
    for (let i = pieces.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [pieces[i], pieces[j]] = [pieces[j], pieces[i]];
    }
    return pieces;
  };

  const postSolution = async () => {
    hashTiles(tiles);
    const res = await axios.post("/api/signMessage", { joinedHashes });
    const signature = res.data.signature;
    console.log("signature", signature);
    const submit = await walletClient?.writeContract({
      address: contractAddr,
      abi: abi,
      functionName: "playGame",
      args: [tileHashes, signature],
    });
    await publicClient?.waitForTransactionReceipt({
      hash: submit as `0x${string}`,
    });
    //we have to give this thing to blockchain
    fetchGameData();
  };

  const hashTiles = (pieces: string[]) => {
    const hashes: string[] = pieces.map((piece) =>
      keccak256(toUtf8Bytes(piece))
    );
    setTileHashes(hashes);
    const concatenated = ethers.solidityPacked(["bytes32[]"], [hashes]);
    setJoinedHashes(concatenated);
    console.log("concatenated", concatenated);
    return keccak256(concatenated);
  };

  const splitImage = async (imageSrc: string, rows: number, cols: number) => {
    const img = new window.Image();
    img.src = imageSrc;
    img.crossOrigin = "anonymous";

    await new Promise((resolve) => {
      img.onload = resolve;
    });

    const mainCanvas = document.createElement("canvas");
    mainCanvas.width = img.width;
    mainCanvas.height = img.height;
    const mainCtx = mainCanvas.getContext("2d");
    mainCtx?.drawImage(img, 0, 0);
    setImage(mainCanvas.toDataURL("image/jpeg", 1));

    const tileWidth = img.width / cols;
    const tileHeight = img.height / rows;
    const canvas = document.createElement("canvas");
    canvas.width = tileWidth;
    canvas.height = tileHeight;
    const ctx = canvas.getContext("2d");

    const pieces = [];
    for (let row = 0; row < rows; row++) {
      for (let col = 0; col < cols; col++) {
        ctx?.clearRect(0, 0, tileWidth, tileHeight);
        ctx?.drawImage(
          img,
          col * tileWidth,
          row * tileHeight,
          tileWidth,
          tileHeight,
          0,
          0,
          tileWidth,
          tileHeight
        );
        pieces.push(canvas.toDataURL("image/jpeg", 1));
      }
    }
    const answerHash = hashTiles(pieces);
    setAnswerHash(answerHash);
    setTiles(shuffleImages(pieces));
  };

  const selectAndSwapTiles = (index2: number) => {
    if (selectedTile === null) {
      setSelectedTile(index2);
      return;
    } else if (selectedTile === index2) {
      setSelectedTile(null);
      return;
    }

    const newTiles = [...tiles];
    const tempTile = newTiles[selectedTile];
    newTiles[selectedTile] = newTiles[index2];
    newTiles[index2] = tempTile;
    setTiles(newTiles);
    setSelectedTile(null);
  };

  return image ? (
    <div className="min-h-screen flex items-center justify-center bg-gray-100 p-6">
      <ToastContainer />
      <div className="w-full max-w-7xl flex flex-col items-center gap-6">
        <div className="text-2xl text-amber-700">Level {level}</div>
        <ConnectButton />

        <div className="flex flex-col md:flex-row gap-6 w-full justify-center items-center">
          {/* Puzzle Grid */}
          <div
            className={`grid border  rounded shadow-lg aspect-[3/2] w-full max-w-xl ${
              currentHash === answerHash
                ? "border-green-400 border-3"
                : "border-gray-300"
            }`}
            style={{
              gridTemplateColumns: `repeat(${level + 2}, 1fr)`,
              gridTemplateRows: `repeat(${level + 2}, 1fr)`,
            }}
          >
            {tiles.map((tile, key) => (
              <NextImage
                key={key}
                src={tile}
                alt={`Tile ${key}`}
                width={50}
                height={50}
                style={{
                  objectFit: "cover",
                  width: "100%",
                  height: "100%",
                  border:
                    selectedTile === key
                      ? "2px solid #6366F1"
                      : "1px solid #E5E7EB",
                }}
                onClick={() => selectAndSwapTiles(key)}
              />
            ))}
          </div>

          {/* Original Image */}
          <div className="w-full max-w-sm border border-gray-300 rounded shadow-md">
            <NextImage
              src={image}
              alt="Original"
              width={50}
              height={50}
              style={{
                objectFit: "cover",
                width: "100%",
                height: "100%",
              }}
            />
          </div>
        </div>

        {level === 0 ? (
          <button
            onClick={enterAndRegisterGame}
            className="bg-blue-600 hover:bg-blue-700 text-white font-semibold px-6 py-2 rounded-md shadow-md transition-all duration-200 active:scale-95"
          >
            Enter Game
          </button>
        ) : (
          <div className="flex gap-4 flex-wrap justify-center mt-4">
            <button
              className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded transition"
              onClick={() => console.log("answer hash", answerHash)}
            >
              Show Answer Hash
            </button>
            <button
              className="bg-yellow-500 hover:bg-yellow-600 text-white px-4 py-2 rounded transition"
              onClick={() => {
                const currentHash = hashTiles(tiles);
                setCurrentHash(currentHash);
                console.log("joined hashes", joinedHashes);
                console.log("current hash", currentHash);
                console.log("tile hashes", tileHashes);
              }}
            >
              Show Current Hash
            </button>
            <button
              className={` text-white px-4 py-2 rounded transition ${
                currentHash === answerHash
                  ? "bg-green-600 hover:bg-green-700"
                  : "cursor-not-allowed bg-gray-400"
              }`}
              onClick={postSolution}
              disabled={currentHash === answerHash ? false : true}
            >
              Submit Solution
            </button>
            <button
              onClick={regsiterGame}
              className="bg-blue-600 hover:bg-blue-700 text-white font-semibold px-6 py-2 rounded-md shadow-md transition-all duration-200 active:scale-95"
            >
              Register Game
            </button>
          </div>
        )}
        <div>
          <div>
            <div className="text-gray-700">
              <span className="font-bold">Answer Hash: </span>
              {answerHash}
            </div>
          </div>
          <div className="text-gray-700" onClick={() => {}}>
            <span className="font-bold">Current Hash: </span>
            {currentHash}
          </div>
        </div>
      </div>
    </div>
  ) : (
    <div>working</div>
  );
}
