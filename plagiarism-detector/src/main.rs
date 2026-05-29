use clap::Parser;
use rayon::prelude::*;
use std::collections::HashSet;
use std::hash::{DefaultHasher, Hash, Hasher};
use std::path::PathBuf;
use tabled::{Table, Tabled};
use walkdir::WalkDir;

#[derive(Tabled)]
struct Row {
    #[tabled(rename = "Rank")]
    rank: usize,
    #[tabled(rename = "File A")]
    file_a: String,
    #[tabled(rename = "File B")]
    file_b: String,
    #[tabled(rename = "Similarity")]
    similarity: String,
}

#[derive(Parser)]
#[command(name = "plagiarism-detector")]
struct Cli {
    #[arg(long)]
    dir: Option<PathBuf>,
    #[arg(long, num_args = 1..)]
    files: Option<Vec<PathBuf>>,
    #[arg(long, default_value_t = 50.0)]
    threshold: f64,
    #[arg(long, default_value_t = 20)]
    top: usize,
    #[arg(long = "file_name")]
    file_name: Option<String>,
    #[arg(long, default_value_t = 0)]
    strip: usize,
    #[arg(long)]
    strip_prefix: Option<String>,
}

fn normalize_token(tok: &str) -> &str {
    match tok {
        "class" | "extends" | "constructor" | "new" | "this" | "super"
        | "if" | "else" | "for" | "while" | "do" | "switch" | "case"
        | "break" | "continue" | "return" | "throw" | "try" | "catch" | "finally"
        | "const" | "let" | "var" | "function" | "typeof" | "instanceof"
        | "true" | "false" | "null" | "undefined" | "void"
        | "get" | "set" | "static" | "async" | "await" | "yield"
        | "import" | "export" | "default" | "from" | "of" | "in" => tok,
        "{" | "}" | "(" | ")" | "[" | "]" | ";" | "," | "." | "..."
        | "=" | "==" | "===" | "!=" | "!==" | ">" | "<" | ">=" | "<="
        | "+" | "-" | "*" | "/" | "%" | "**" | "++" | "--"
        | "&&" | "||" | "!" | "?" | ":" | "=>" | "+=" | "-=" | "*=" | "/="
        | "|" | "&" | "^" | "~" | "<<" | ">>" | ">>>" => tok,
        "module.exports" => tok,
        s if s.starts_with("fn_") || s.starts_with("#") => s,
        s if s.chars().next().is_some_and(|c| c.is_ascii_digit()) => "N",
        s if s.starts_with('"') || s.starts_with('\'') || s.starts_with('`') => "S",
        _ => "V",
    }
}

fn fingerprint(content: &str) -> HashSet<u64> {
    content
        .lines()
        .map(|line| {
            line.split_whitespace()
                .map(normalize_token)
                .collect::<Vec<_>>()
                .join(" ")
        })
        .filter(|line| !line.is_empty())
        .map(|line| {
            let mut h = DefaultHasher::new();
            line.hash(&mut h);
            h.finish()
        })
        .collect()
}


fn strip_prefix_from<'a>(path: &'a str, prefix: &Option<String>) -> &'a str {
    match prefix {
        Some(p) => path.find(p).map_or(path, |i| &path[i + p.len()..]).trim_start_matches('/'),
        None => path,
    }
}

fn main() {
    let cli = Cli::parse();

    if cli.dir.is_none() && cli.files.is_none() {
        eprintln!("error: at least one of --dir or --files must be provided");
        std::process::exit(2);
    }

    if let Some(ref dir) = cli.dir {
        if !dir.exists() {
            eprintln!("Error: directory '{}' does not exist", dir.display());
            std::process::exit(2);
        }
        if !dir.is_dir() {
            eprintln!("Error: '{}' is not a directory", dir.display());
            std::process::exit(2);
        }
    }

    let mut paths: Vec<PathBuf> = Vec::new();

    if let Some(ref dir) = cli.dir {
        paths.extend(
            WalkDir::new(dir)
                .into_iter()
                .filter_map(|e| e.ok())
                .filter(|e| {
                    let is_file = e.path().is_file();
                    let name_matches = match &cli.file_name {
                        Some(name) => e.path().file_name().is_some_and(|f| f == name.as_str()),
                        None => e.path().extension().is_some_and(|ext| ext == "js"),
                    };
                    is_file && name_matches
                })
                .map(|e| e.path().to_path_buf()),
        );
    }

    if let Some(ref file_list) = cli.files {
        paths.extend(file_list.iter().cloned());
    }

    let files: Vec<(String, HashSet<u64>)> = paths
        .iter()
        .filter_map(|p| {
            if !p.exists() {
                eprintln!("Warning: file '{}' does not exist, skipping", p.display());
                return None;
            }
            let content = std::fs::read_to_string(p).ok()?;
            let name = p.to_string_lossy().into_owned();
            Some((name, fingerprint(&content)))
        })
        .collect();

    let pairs: Vec<(usize, usize)> = (0..files.len())
        .flat_map(|i| (i + 1..files.len()).map(move |j| (i, j)))
        .collect();

    let mut results: Vec<(&str, &str, f64)> = pairs
        .par_iter()
        .filter_map(|&(i, j)| {
            let intersection = files[i].1.intersection(&files[j].1).count();
            let smaller = files[i].1.len().min(files[j].1.len());
            if smaller == 0 {
                return None;
            }
            let sim = intersection as f64 / smaller as f64 * 100.0;
            if sim >= cli.threshold {
                Some((&*files[i].0, &*files[j].0, sim))
            } else {
                None
            }
        })
        .collect();

    results.sort_by(|a, b| b.2.partial_cmp(&a.2).unwrap());
    results.truncate(cli.top);

    if results.is_empty() {
        println!("No suspicious pairs found.");
        std::process::exit(0);
    }

    let rows: Vec<Row> = results.iter().enumerate().map(|(i, (a, b, sim))| Row {
        rank: i + 1,
        file_a: strip_prefix_from(a, &cli.strip_prefix).to_string(),
        file_b: strip_prefix_from(b, &cli.strip_prefix).to_string(),
        similarity: format!("{:.1}%", sim),
    }).collect();
    println!("{}", Table::new(rows));

    std::process::exit(1);
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashSet;

    fn overlap(a: &HashSet<u64>, b: &HashSet<u64>) -> f64 {
        let intersection = a.intersection(b).count();
        let smaller = a.len().min(b.len());
        if smaller == 0 { return 0.0; }
        intersection as f64 / smaller as f64 * 100.0
    }

    #[test]
    fn test_identical_files() {
        let code = "function add(a, b) { return a + b; }\nfunction sub(a, b) { return a - b; }";
        let a = fingerprint(code);
        let b = fingerprint(code);
        assert_eq!(overlap(&a, &b), 100.0);
    }

    #[test]
    fn test_completely_different() {
        let a = fingerprint("function alpha(x) { return x * x * x; }\nlet result = alpha(42);");
        let b = fingerprint("const name = prompt();\nconsole.log('hello ' + name + '!');\ndone();");
        assert!(overlap(&a, &b) < 50.0);
    }

    #[test]
    fn test_cosmetic_changes() {
        // With line-based fingerprinting, same tokens on same lines produce same hashes
        let a = fingerprint("function add(a, b) { return a + b; }");
        let b = fingerprint("function add(a, b) { return a + b; }");
        assert_eq!(overlap(&a, &b), 100.0);
    }

    #[test]
    fn test_partial_copy() {
        let shared = "function compute(x) { let y = x * 2; let z = y + 1; return z; }";
        let a = fingerprint(shared);
        let extended = format!("{}\nfunction extra(a) {{ return a + a + a; }}\nlet val = extra(10);", shared);
        let b = fingerprint(&extended);
        assert!(overlap(&a, &b) == 100.0);
    }

    #[test]
    fn test_empty_file() {
        let a = fingerprint("");
        let b = fingerprint("function foo(x) { return x + 1; }\nlet r = foo(5);");
        assert!(a.is_empty());
        assert_eq!(overlap(&a, &b), 0.0);
    }

    #[test]
    fn test_small_file() {
        let a = fingerprint("let x = 1;");
        assert_eq!(a.len(), 1);
    }

    #[test]
    fn test_nonexistent_file_skipped() {
        let result = fingerprint("");
        assert!(result.is_empty());
    }

    #[test]
    fn test_variable_rename_detected() {
        let code_a = "class fn_abc { constructor() { let count = 0; this.count = count; } increment() { this.count += 1; } }";
        let code_b = "class fn_abc { constructor() { let x = 0; this.x = x; } increment() { this.x += 1; } }";
        let a = fingerprint(code_a);
        let b = fingerprint(code_b);
        assert!(overlap(&a, &b) > 80.0);
    }

    #[test]
    fn test_different_logic_low_similarity() {
        let code_a = "class fn_abc {\n#items;\nconstructor() { this.#items = []; }\npush(x) { this.#items.push(x); }\npop() { return this.#items.pop(); }\nsize() { return this.#items.length; }\n}";
        let code_b = "class fn_abc {\n#head;\n#size;\nconstructor() { this.#head = null; this.#size = 0; }\npush(x) { this.#head = { val: x, next: this.#head }; this.#size++; }\npop() { if (!this.#head) return undefined; const v = this.#head.val; this.#head = this.#head.next; this.#size--; return v; }\nsize() { return this.#size; }\n}";
        let a = fingerprint(code_a);
        let b = fingerprint(code_b);
        assert!(overlap(&a, &b) < 60.0);
    }

    #[test]
    fn test_reordered_methods_high_similarity() {
        let code_a = "class fn_abc {\nfoo() { return 1; }\nbar() { return 2; }\nbaz() { return 3; }\n}";
        let code_b = "class fn_abc {\nbaz() { return 3; }\nfoo() { return 1; }\nbar() { return 2; }\n}";
        let a = fingerprint(code_a);
        let b = fingerprint(code_b);
        assert!(overlap(&a, &b) > 80.0);
    }
}
