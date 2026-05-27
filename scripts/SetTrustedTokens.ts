import { network } from 'hardhat';
import { join } from 'path';
import { getContractAtAddress, parseCLIArgs } from './helpers';
import { readFileSync } from 'fs';
import { SwapExecutor } from '../types/ethers-contracts';
import constants from './constants.json';

interface Output {
  routers: string[];
  swapExecutor: string;
}

const trustedTokens = {
  arcTestnet: ['0xf0C4a4CE82A5746AbAAd9425360Ab04fbBA432BF', '0x64FAF984Bf60dE19e24238521814cA98574E3b00'],
};

async function core() {
  const cliArgs = parseCLIArgs();
  const networkName = cliArgs.values.network as string;
  console.log(networkName);

  const { networkConfig } = await network.connect({ network: networkName });
  const outputDirectory = 'scripts/deployments';
  const outputFile = join(process.cwd(), outputDirectory, `CoreOutput-${String(networkConfig.chainId)}.json`);

  const buffer = readFileSync(outputFile);
  const output: Output = JSON.parse(buffer.toString());

  const router = await getContractAtAddress<SwapExecutor>('arcTestnet', 'SwapExecutor', output.swapExecutor);
  const tt = constants[networkName as keyof typeof constants].trustedTokens;
  await router.setTrustedTokens(tt.concat(trustedTokens[networkName as keyof typeof trustedTokens]));
}

core().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
