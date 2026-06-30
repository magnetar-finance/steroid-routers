import { SwapExecutor, ZeroDexRouter } from '../types/ethers-contracts';
import { deployContract, getContractAtAddress, parseCLIArgs } from './helpers';
import { createWriteStream, existsSync, readFileSync } from 'fs';
import { join } from 'path';
import { writeFile } from 'fs/promises';

const ZERODEX_ROUTER = '0xd808DBF8b8d1Cd9ea9C5449336C764cCbC67D4B7'; // ZeroDex router address on LitVM Testnet
const WETH = '0xeb29947d9c1cd59af2b413b47505bf89a47be0d4'; // WETH contract address on LitVM Testnet

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

  const zeroDex = await deployContract<ZeroDexRouter>(networkName, 'ZeroDexRouter', undefined, ZERODEX_ROUTER, WETH);
  const address = await zeroDex.getAddress();

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
