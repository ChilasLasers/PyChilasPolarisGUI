"""
Script to create a standalone binary executable for the Chilas Polaris application.
"""

import PyInstaller.__main__
from PySide2.QtWidgets import QApplication, QFileDialog
import os

app = QApplication()

path, type = QFileDialog.getSaveFileName(
    caption="Where save binary?",
    filter="Executable (*.exe)",
    selectedFilter="Executable (*.exe)",
)
name = os.path.basename(path)
path = os.path.dirname(path)

PyInstaller.__main__.run(
    [
        "main.py",
        "--onefile",
        "--windowed",
        "--icon=resources\\icons\\icon.ico",
        "--add-data",
        f"resources\\images\\background.png;.",
        "--add-data",
        f"resources\\images\\chilas_logo.png;.",
        "--add-data",
        f"resources\\images\\polaris_logo.png;.",
        "--add-data",
        f"Control.qml;.",
        "--add-data",
        f"main.qml;.",
        "--add-data",
        f"PageCntrlPnl.qml;.",
        "--add-data",
        f"PopupInfo.qml;.",
        "--add-data",
        f"Splash.qml;.",
        "--add-data",
        f"LICENSE;.",
        f"-n{name}",
        f"--distpath={path}",
    ]
)
