use std::path::PathBuf;
use futures_util::{Stream, stream};
use std::fs::File;
use std::io::{BufReader, Read};

pub fn ipc_stream(input_pipe_path: PathBuf) -> impl Stream<Item = Result<String, std::io::Error>> {
    let stream = stream::unfold(input_pipe_path, |path| async {
        let path_clone = path.clone();
        let result = tokio::task::spawn_blocking(move || {
            read_from_pipe(&path_clone)
        }).await;

        match result {
            Err(e) => Some((Err(e.into()), path)),
            Ok(line) => Some((line, path)),
        }
    });

    stream
}

fn read_from_pipe(path: &PathBuf) -> Result<String, std::io::Error> {
    let input_file = File::open(&path)?;
    let mut input_file = BufReader::new(input_file);
    let mut line = String::new();
    match input_file.read_to_string(&mut line) {
        Ok(_) => Ok(line),
        Err(e) => Err(e),
    }
}
