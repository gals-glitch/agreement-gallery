import React from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Download, X, ChevronLeft, ChevronRight } from 'lucide-react';
import { AgreementDocument, AgreementDocumentVersion } from '@/types/agreementDocs';

interface PdfViewerModalProps {
  open: boolean;
  onClose: () => void;
  document: AgreementDocument | null;
  versions: AgreementDocumentVersion[];
  currentVersion: number;
  onVersionChange: (version: number) => void;
  downloadUrl: string | null;
}

export function PdfViewerModal({
  open,
  onClose,
  document,
  versions,
  currentVersion,
  onVersionChange,
  downloadUrl,
}: PdfViewerModalProps) {
  if (!document) return null;

  const currentVersionIndex = versions.findIndex(v => v.version_number === currentVersion);
  const canGoPrevious = currentVersionIndex > 0;
  const canGoNext = currentVersionIndex < versions.length - 1;

  const handlePrevious = () => {
    if (canGoPrevious) {
      onVersionChange(versions[currentVersionIndex - 1].version_number);
    }
  };

  const handleNext = () => {
    if (canGoNext) {
      onVersionChange(versions[currentVersionIndex + 1].version_number);
    }
  };

  const handleDownload = () => {
    if (downloadUrl) {
      window.open(downloadUrl, '_blank');
    }
  };

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-6xl h-[90vh] p-0">
        <DialogHeader className="px-6 py-4 border-b">
          <div className="flex items-center justify-between">
            <div>
              <DialogTitle>{document.filename}</DialogTitle>
              <p className="text-sm text-muted-foreground mt-1">
                Version {currentVersion} of {versions.length}
                {versions[currentVersionIndex] && (
                  <span className="ml-2">
                    • Uploaded {new Date(versions[currentVersionIndex].uploaded_at).toLocaleDateString()}
                  </span>
                )}
              </p>
            </div>

            <div className="flex items-center gap-2">
              {/* Version Navigation */}
              <Button
                variant="outline"
                size="icon"
                onClick={handlePrevious}
                disabled={!canGoPrevious}
                title="Previous version"
              >
                <ChevronLeft className="h-4 w-4" />
              </Button>

              <Button
                variant="outline"
                size="icon"
                onClick={handleNext}
                disabled={!canGoNext}
                title="Next version"
              >
                <ChevronRight className="h-4 w-4" />
              </Button>

              {/* Download Button */}
              <Button
                variant="outline"
                size="icon"
                onClick={handleDownload}
                disabled={!downloadUrl}
                title="Download"
              >
                <Download className="h-4 w-4" />
              </Button>

              {/* Close Button */}
              <Button
                variant="ghost"
                size="icon"
                onClick={onClose}
                title="Close"
              >
                <X className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </DialogHeader>

        {/* PDF Viewer */}
        <div className="flex-1 overflow-hidden">
          {downloadUrl ? (
            <iframe
              src={downloadUrl}
              className="w-full h-full border-0"
              title={`${document.filename} - Version ${currentVersion}`}
            />
          ) : (
            <div className="flex items-center justify-center h-full">
              <p className="text-muted-foreground">Loading document...</p>
            </div>
          )}
        </div>

        {/* Version Info Footer */}
        {versions[currentVersionIndex] && (
          <div className="px-6 py-3 border-t bg-muted/50 text-xs text-muted-foreground">
            <div className="flex items-center justify-between">
              <span>
                Uploaded by {versions[currentVersionIndex].uploaded_by_name || 'Unknown'} on{' '}
                {new Date(versions[currentVersionIndex].uploaded_at).toLocaleString()}
              </span>
              <span>
                {(versions[currentVersionIndex].file_size_bytes / 1024).toFixed(1)} KB
              </span>
            </div>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
