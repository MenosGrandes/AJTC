import {readFileSync} from 'node:fs'
import {minifySync} from 'oxc-minify'
import {format} from 'oxfmt'

const file = process.argv[2]
const code = readFileSync(file, 'utf-8')
const { code : minified} = minifySync(file,code, {compress : false, mangle: false});
const {code : formatted} = await format(file,minified,{});
process.stdout.write(formatted)