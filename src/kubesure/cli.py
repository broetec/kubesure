import typer

from kubesure import __version__

app = typer.Typer(
    help='Kubesure: Static validation and standardization of k8s manifests.',
    add_completion=False,
)


@app.command()
def check(
    path: str = typer.Argument('.', help='Path to the directory or YAML file'),
):
    """
    Start the validation of YAML manifests in the specified directory.
    """
    # Here we will call the kubeconform, helm, etc. in the future.
    typer.echo(f'Hello World! Preparing to validate the manifests in: {path}')


@app.command()
def version():
    """
    Display the current version of Kubesure.
    """
    typer.echo(f'Kubesure v{__version__}')


if __name__ == '__main__':
    app()
