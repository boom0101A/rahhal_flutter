const fs = require('fs');
const path = require('path');

function getFilesRecursively(dir, fileList = []) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const name = path.join(dir, file);
    if (fs.statSync(name).isDirectory()) {
      // Ignore build / tools / system directories
      if (!['.git', '.dart_tool', 'build', 'android', 'ios', 'windows', 'web', 'rahhal_codebase_md', 'node_modules'].includes(file)) {
        getFilesRecursively(name, fileList);
      }
    } else {
      const ext = path.extname(file);
      if (['.dart', '.yaml', '.json', '.js'].includes(ext)) {
        fileList.push(name);
      }
    }
  }
  return fileList;
}

function exportToMd() {
  const projectDir = __dirname;
  const outputFilename = 'rahhal_full_codebase.md';
  const outputPath = path.join(projectDir, outputFilename);

  const topLevelFiles = ['pubspec.yaml', 'server.js', 'README.md'];
  const libDir = path.join(projectDir, 'lib');

  let mdContent = '';
  mdContent += '# Rahhal AI Complete Codebase Export\n';
  mdContent += `Generated on: ${new Date().toLocaleString()}\n`;
  mdContent += 'This file contains the complete source code for the Rahhal Flutter application backend and frontend.\n\n---\n\n';

  // 1. Export top-level files
  for (const file of topLevelFiles) {
    const filepath = path.join(projectDir, file);
    if (fs.existsSync(filepath)) {
      console.log(`Exporting top-level file: ${file}`);
      mdContent += `## File: \`${file}\`\n`;
      const ext = path.extname(file);
      const lang = ext === '.yaml' ? 'yaml' : ext === '.js' ? 'javascript' : ext === '.md' ? 'markdown' : 'text';
      mdContent += `\`\`\`${lang}\n`;
      try {
        mdContent += fs.readFileSync(filepath, 'utf8');
      } catch (err) {
        mdContent += `// Error reading file: ${err.message}`;
      }
      mdContent += '\n\`\`\`\n\n---\n\n';
    }
  }

  // 2. Export lib directory
  if (fs.existsSync(libDir)) {
    const allLibFiles = getFilesRecursively(libDir);
    for (const filepath of allLibFiles) {
      const relPath = path.relative(projectDir, filepath).replace(/\\/g, '/');
      console.log(`Exporting: ${relPath}`);
      mdContent += `## File: \`${relPath}\`\n`;
      const ext = path.extname(filepath);
      const lang = ext === '.dart' ? 'dart' : ext === '.yaml' ? 'yaml' : ext === '.json' ? 'json' : ext === '.js' ? 'javascript' : 'text';
      mdContent += `\`\`\`${lang}\n`;
      try {
        mdContent += fs.readFileSync(filepath, 'utf8');
      } catch (err) {
        mdContent += `// Error reading file: ${err.message}`;
      }
      mdContent += '\n\`\`\`\n\n---\n\n';
    }
  }

  fs.writeFileSync(outputPath, mdContent, 'utf8');
  console.log(`\nSuccessfully generated codebase markdown export at: ${outputPath}`);
}

exportToMd();
