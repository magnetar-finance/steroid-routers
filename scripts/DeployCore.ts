import { network } from 'hardhat';
import { createWriteStream, existsSync, readFileSync } from 'fs';
import { writeFile } from 'fs/promises';
import { join } from 'path';
import { SwapExecutor } from '../types/ethers-contracts';
import Constants from './constants.json';
import { deployContract, parseCLIArgs } from './helpers';
import { MagnetarV2Router } from '../types/ethers-contracts/integrations/routers/MagnetarV2Router';
import { MagnetarV3Router } from '../types/ethers-contracts/integrations/routers/MagnetarV3Router';

// Output definition
interface Output {
  routers: string[];
  swapExecutor: string;
}

async function core() {
  // Get CLI args
  const cliArgs = parseCLIArgs();
  const networkName = cliArgs.values.network as string;
  console.log(networkName);
  // Get constants
  const constants = Constants[networkName as keyof typeof Constants];
  const routers: string[] = [];
  // Deploy MagnetarV2
  const magnetarV2 = await deployContract<MagnetarV2Router>(
    networkName,
    'MagnetarV2Router',
    undefined,
    constants.magnetarV2Router,
  );
  routers.push(await magnetarV2.getAddress());
  // Deploy MagnetarV3
  const magnetarV3 = await deployContract<MagnetarV3Router>(
    networkName,
    'MagnetarV3Router',
    undefined,
    constants.magnetarV3Router,
    constants.magnetarV3Factory,
  );
  routers.push(await magnetarV3.getAddress());

  // Deploy swap executor
  const swapExecutor = await deployContract<SwapExecutor>(
    networkName,
    'SwapExecutor',
    undefined,
    constants.team,
    routers,
    '1000',
    constants.weth,
    constants.trustedTokens,
  );

  const { networkConfig } = await network.connect({ network: networkName });
  const outputDirectory = 'scripts/deployments';
  const outputFile = join(process.cwd(), outputDirectory, `CoreOutput-${String(networkConfig.chainId)}.json`);

  const output: Output = { routers, swapExecutor: await swapExecutor.getAddress() };

  try {
    if (!existsSync(outputFile)) {
      const ws = createWriteStream(outputFile);
      ws.write(JSON.stringify(output, null, 2));
      ws.end();
    } else {
      // Read file's content
      const content = readFileSync(outputFile);
      const out = JSON.parse(content.toString());
      // Mutate file
      Object.keys(output).forEach(key => {
        out[key] = output[key as keyof typeof output];
      });
      await writeFile(outputFile, JSON.stringify(out, null, 2));
    }
  } catch (err) {
    console.error(`Error writing output file: ${err}`);
  }
}

core().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
