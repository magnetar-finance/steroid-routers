import { network } from 'hardhat';
import { join } from 'path';
import { getContractAtAddress, parseCLIArgs } from './helpers';
import { readFileSync } from 'fs';
import { SwapExecutor } from '../types/ethers-contracts';

interface Output {
  routers: string[];
  swapExecutor: string;
}

async function core() {
  const cliArgs = parseCLIArgs();
  const networkName = cliArgs.values.network as string;
  console.log(networkName);

  const { networkConfig } = await network.connect({ network: networkName });
  const outputDirectory = 'scripts/deployments';
  const outputFile = join(process.cwd(), outputDirectory, `CoreOutput-${String(networkConfig.chainId)}.json`);

  const buffer = readFileSync(outputFile);
  const output: Output = JSON.parse(buffer.toString());

  const router = await getContractAtAddress<SwapExecutor>(networkName, 'SwapExecutor', output.swapExecutor);
  await router.switchRouterActiveStatus('0x520845956E93138B7Fd812DB956636712591493f');
}

core().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
