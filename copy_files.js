import path from "node:path";
import fse from "fs-extra";
import dotenv from "dotenv";
dotenv.config();

// Path to computer directory in your save (\saves\<save name>\computercraft\computer)
const computerPath = process.env.COMPUTERCRAFT_PATH;

// What computers to be copied to
const computers = [0, 1];
const srcPath = "./src";

computers.forEach(computer => {
    console.log("Copying to computer", computer)
    fse.copySync(srcPath, path.join(computerPath, computer.toString()), {overwrite: true})
})
