#!/usr/bin/env node

/**
 * CI Guard: Prevent legacy REST API usage
 * Fails if rest/v1 is found in src/ directory (excluding type definitions)
 *
 * Usage: node scripts/check-legacy.js
 * Exit code: 0 = pass, 1 = fail
 */

import { readFileSync, readdirSync, statSync } from 'fs';
import { join, extname } from 'path';

const SRC_DIR = join(process.cwd(), 'src');
const EXCLUDED_PATTERNS = [
  /\.d\.ts$/, // Type definition files
  /node_modules/,
];

function getAllFiles(dir, files = []) {
  const entries = readdirSync(dir);

  for (const entry of entries) {
    const fullPath = join(dir, entry);
    const stat = statSync(fullPath);

    if (stat.isDirectory()) {
      if (!EXCLUDED_PATTERNS.some(p => p.test(fullPath))) {
        getAllFiles(fullPath, files);
      }
    } else if (['.ts', '.tsx', '.js', '.jsx'].includes(extname(fullPath))) {
      if (!EXCLUDED_PATTERNS.some(p => p.test(fullPath))) {
        files.push(fullPath);
      }
    }
  }

  return files;
}

function checkFile(filePath) {
  const content = readFileSync(filePath, 'utf-8');
  const lines = content.split('\n');
  const violations = [];

  lines.forEach((line, index) => {
    if (line.includes('rest/v1')) {
      violations.push({
        file: filePath.replace(process.cwd(), '.'),
        line: index + 1,
        content: line.trim(),
      });
    }
  });

  return violations;
}

function main() {
  console.log('🔍 Checking for legacy REST API usage (rest/v1)...\n');

  const files = getAllFiles(SRC_DIR);
  const allViolations = [];

  for (const file of files) {
    const violations = checkFile(file);
    allViolations.push(...violations);
  }

  if (allViolations.length > 0) {
    console.error('❌ Legacy REST API usage detected:\n');
    allViolations.forEach(v => {
      console.error(`  ${v.file}:${v.line}`);
      console.error(`    ${v.content}\n`);
    });
    console.error(`\n⚠️  Found ${allViolations.length} violation(s). Please use the centralized API client instead.\n`);
    process.exit(1);
  }

  console.log('✅ No legacy REST API usage found. All clear!\n');
  process.exit(0);
}

main();
