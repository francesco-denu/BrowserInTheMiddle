import sys
import os
from PyQt5.QtCore import QUrl
from PyQt5.QtWidgets import QApplication
from PyQt5.QtWebEngineWidgets import QWebEngineView

class WebViewer(QWebEngineView):
    def __init__(self, url):
        super().__init__()
        self.setUrl(QUrl(url))
        self.showFullScreen()  # Open in full screen

if __name__ == "__main__":
    os.environ['QTWEBENGINE_CHROMIUM_FLAGS'] = '--no-sandbox'

    app = QApplication(sys.argv)

    # Check if a URL is passed as a command-line argument
    if len(sys.argv) > 1:
        url = sys.argv[1]
    else:
        print("Usage: python script.py <url>")
        sys.exit(1)

    viewer = WebViewer(url)
    sys.exit(app.exec_())



