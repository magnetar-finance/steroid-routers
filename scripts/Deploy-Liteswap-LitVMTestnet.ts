import { SwapExecutor, UniswapV2Router } from '../types/ethers-contracts';
import { deployContract, getContractAtAddress, parseCLIArgs } from './helpers';
import { createWriteStream, existsSync, readFileSync } from 'fs';
import { join } from 'path';
import { writeFile } from 'fs/promises';

const ROUTER_ADDRESS = '0xF456737D17C2Bbb348fd4F7D1b000D62A46FB3b5'; // Liteswap router address on Liteforge

// Output definition
interface Output {
  routers: string[];
  swapExecutor: string;
  v2SwapExecutor: string;
  v3SwapExecutor: string;
}

async function core() {
  // Get CLI args
  const cliArgs = parseCLIArgs();
  const networkName = cliArgs.values.network as string;

  const uniswapV2 = await deployContract<UniswapV2Router>(networkName, 'UniswapV2Router', undefined, ROUTER_ADDRESS);
  const address = await uniswapV2.getAddress();

  const outputDirectory = 'scripts/deployments';
  const outputFile = join(process.cwd(), outputDirectory, 'CoreOutput-4441.json');
  const outputBuffer = readFileSync(outputFile);
  const output: Output = JSON.parse(outputBuffer.toString());

  // Swap executor
  const swapExecutor = await getContractAtAddress<SwapExecutor>(networkName, 'SwapExecutor', output.swapExecutor);
  await swapExecutor.addRouters([address]);
  output.routers.push(address);

  try {
    if (!existsSync(outputFile)) {
      const ws = createWriteStream(outputFile);
      ws.write(JSON.stringify(output, null, 2));
      ws.end();
    } else {
      await writeFile(outputFile, JSON.stringify(output, null, 2));
    }
  } catch (err) {
    console.error(`Error writing output file: ${err}`);
  }
}

core().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
