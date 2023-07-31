use std::path::PathBuf;
use futures_util::{Stream, stream};
use std::fs::{File, OpenOptions};
use std::io::{BufReader, BufWriter, Read, Write};
use tokio::task;

pub static mut IPC: Option<Ipc> = None;

#[derive(Clone)]
pub struct Ipc {
    input_pipe_path: PathBuf,
    output_pipe_path: PathBuf,
}

impl Ipc {

    pub fn new(input_pipe_path: Option<PathBuf>, output_pipe_path: Option<PathBuf>) -> Option<Self> {
        let input_pipe_path = match input_pipe_path {
            Some(path) => path,
            None => return None,
        };

        let output_pipe_path = match output_pipe_path {
            Some(path) => path,
            None => return None,
        };

        Some(Ipc { input_pipe_path, output_pipe_path })
    }

    pub fn ipc_stream(&self) -> impl Stream<Item = Result<String, std::io::Error>> {
        let path = self.input_pipe_path.clone();
        let stream = stream::unfold(path, |path| async move {
            unsafe {
                let Some(ipc) = IPC.clone() else { return None; };

                let result = ipc.receive_event().await;

                match result {
                    Err(e) => Some((Err(e.into()), path)),
                    Ok(line) => Some((Ok(line), path)),
                }
            }
        });

        stream
    }

    pub async fn end_ipc_stream(&self) -> Result<(), std::io::Error> {
        self.send_input_event("exit".to_string()).await
    }

    pub async fn receive_event(&self) -> Result<String, std::io::Error> {
        let path = self.input_pipe_path.clone();
        task::spawn_blocking(move || {
            Ipc::read_from_pipe(&path)
        }).await?
    }

    pub async fn send_input_event(&self, event: String) -> Result<(), std::io::Error> {
        let path = self.input_pipe_path.clone();
        task::spawn_blocking(move || {
            Ipc::write_to_pipe(&path, event)
        }).await?
    }

    pub async fn send_output_event(&self, event: String) -> Result<(), std::io::Error> {
        let path = self.output_pipe_path.clone();
        task::spawn_blocking(move || {
            Ipc::write_to_pipe(&path, event)
        }).await?
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

    fn write_to_pipe(path: &PathBuf, line: String) -> Result<(), std::io::Error> {
        let output_file = OpenOptions::new().write(true).open(&path)?;
        let mut output_file = BufWriter::new(output_file);
        match output_file.write(line.as_bytes()) {
            Ok(_) => Ok(()),
            Err(e) => Err(e),
        }
    }
}
