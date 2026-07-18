const fs = require('fs');
const path = require('path');

const rootDir = __dirname;
const outputFile = path.join(rootDir, 'rahhal_full_codebase.txt');

const filesToInclude = [
  'server.js',
  'package.json',
  'pubspec.yaml',
  '.env.example'
];

const dirsToInclude = [
  'lib'
];

function getAllFiles(dirPath, arrayOfFiles = []) {
  const files = fs.readdirSync(dirPath);

  files.forEach(file => {
    const fullPath = path.join(dirPath, file);
    if (fs.statSync(fullPath).isDirectory()) {
      if (file !== 'node_modules' && file !== '.git' && file !== 'build' && file !== '.dart_tool') {
        getAllFiles(fullPath, arrayOfFiles);
      }
    } else {
      if (file.endsWith('.dart') || file.endsWith('.json') || file.endsWith('.yaml') || file.endsWith('.js')) {
        arrayOfFiles.push(fullPath);
      }
    }
  });

  return arrayOfFiles;
}

let content = `# Rahhal AI Complete Codebase Export\n`;
content += `Generated on: ${new Date().toLocaleString()}\n`;
content += `This file contains the complete source code for the Rahhal Flutter application backend and frontend.\n\n---\n\n`;

// Include individual files
for (const relFile of filesToInclude) {
  const fullPath = path.join(rootDir, relFile);
  if (fs.existsSync(fullPath)) {
    console.log(`Adding ${relFile}...`);
    const fileData = fs.readFileSync(fullPath, 'utf8');
    const ext = path.extname(relFile).substring(1) || 'text';
    content += `## File: \`${relFile}\`\n\`\`\`${ext}\n${fileData}\n\`\`\`\n\n---\n\n`;
  }
}

// Include directories
for (const dir of dirsToInclude) {
  const fullPath = path.join(rootDir, dir);
  if (fs.existsSync(fullPath)) {
    const files = getAllFiles(fullPath);
    files.sort();
    for (const file of files) {
      const relPath = path.relative(rootDir, file).replace(/\\/g, '/');
      console.log(`Adding ${relPath}...`);
      const fileData = fs.readFileSync(file, 'utf8');
      const ext = path.extname(file).substring(1) || 'dart';
      content += `## File: \`${relPath}\`\n\`\`\`${ext}\n${fileData}\n\`\`\`\n\n---\n\n`;
    }
  }
}

fs.writeFileSync(outputFile, content, 'utf8');
console.log(`\nSuccessfully updated ${outputFile} (${(fs.statSync(outputFile).size / 1024 / 1024).toFixed(2)} MB)`);
