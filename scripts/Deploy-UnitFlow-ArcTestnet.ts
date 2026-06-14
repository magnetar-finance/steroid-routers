import { SwapExecutor, UnitFlowRouter } from '../types/ethers-contracts';
import { deployContract, getContractAtAddress, parseCLIArgs } from './helpers';
import { createWriteStream, existsSync, readFileSync } from 'fs';
import { join } from 'path';
import { writeFile } from 'fs/promises';

const ROUTER_ADDRESS = '0x4AA8c7Ac458479d9A4FA5c1481e03061ac76824A'; // Unitflow router address on Arc Testnet

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

  const unitFlow = await deployContract<UnitFlowRouter>(networkName, 'UnitFlowRouter', undefined, ROUTER_ADDRESS);
  const address = await unitFlow.getAddress();

  const outputDirectory = 'scripts/deployments';
  const outputFile = join(process.cwd(), outputDirectory, 'CoreOutput-5042002.json');
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
