import { SwapExecutor, MultyraRouter } from '../types/ethers-contracts';
import { deployContract, getContractAtAddress, parseCLIArgs } from './helpers';
import { createWriteStream, existsSync, readFileSync } from 'fs';
import { join } from 'path';
import { writeFile } from 'fs/promises';

const SWAP_ROUTER = '0x97A0A49BF8B5EF5033F18855bE7ff6F0dA34a913'; // swap router address on Liteforge
const FACTORY_ADDRESS = '0x2305fd1Ebc0f5F3b59bdD06cda6090a4EBe7714D';

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

  const multyra = await deployContract<MultyraRouter>(
    networkName,
    'MultyraRouter',
    undefined,
    SWAP_ROUTER,
    FACTORY_ADDRESS,
  );
  const address = await multyra.getAddress();

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
