import { Wallet, keccak256, getBytes } from "ethers";

const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const wallet = new Wallet(PRIVATE_KEY);

export async function POST(request: Request) {
  const body = await request.json();
  const joinedHashes: string = body.joinedHashes;
  if (!joinedHashes || joinedHashes.length === 0) {
    return new Response("Invalid input", { status: 400 });
  }
  const mainHash = keccak256(joinedHashes);

  const sig = await wallet.signMessage(getBytes(mainHash));
  return new Response(
    JSON.stringify({
      signature: sig,
    })
  );
}
