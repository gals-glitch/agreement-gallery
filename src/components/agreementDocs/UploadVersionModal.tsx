import React, { useState, useCallback } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Upload, FileText, AlertCircle } from 'lucide-react';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Progress } from '@/components/ui/progress';
import { calculateFileSHA256 } from '@/types/agreementDocs';
import { useToast } from '@/hooks/use-toast';

interface UploadVersionModalProps {
  open: boolean;
  onClose: () => void;
  documentId: string;
  onUploadComplete: () => void;
}

export function UploadVersionModal({
  open,
  onClose,
  documentId,
  onUploadComplete,
}: UploadVersionModalProps) {
  const { toast } = useToast();
  const [file, setFile] = useState<File | null>(null);
  const [notes, setNotes] = useState('');
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [sha256, setSha256] = useState<string | null>(null);
  const [dragActive, setDragActive] = useState(false);

  const handleDrag = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === 'dragenter' || e.type === 'dragover') {
      setDragActive(true);
    } else if (e.type === 'dragleave') {
      setDragActive(false);
    }
  }, []);

  const handleDrop = useCallback(async (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);

    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      const droppedFile = e.dataTransfer.files[0];
      await handleFileSelection(droppedFile);
    }
  }, []);

  const handleFileSelection = async (selectedFile: File) => {
    // Validate file type
    const allowedTypes = [
      'application/pdf',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/msword',
      'image/png',
      'image/jpeg',
      'image/gif',
      'text/plain',
    ];

    if (!allowedTypes.includes(selectedFile.type)) {
      toast({
        title: 'Invalid file type',
        description: 'Please upload PDF, DOCX, DOC, PNG, JPEG, GIF, or TXT files only.',
        variant: 'destructive',
      });
      return;
    }

    // Validate file size (50MB limit)
    const maxSize = 50 * 1024 * 1024; // 50MB
    if (selectedFile.size > maxSize) {
      toast({
        title: 'File too large',
        description: 'Please upload files smaller than 50MB.',
        variant: 'destructive',
      });
      return;
    }

    setFile(selectedFile);

    // Calculate SHA-256 hash
    try {
      const hash = await calculateFileSHA256(selectedFile);
      setSha256(hash);
    } catch (error) {
      console.error('Error calculating SHA-256:', error);
      toast({
        title: 'Error',
        description: 'Failed to calculate file hash.',
        variant: 'destructive',
      });
    }
  };

  const handleFileInputChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      await handleFileSelection(e.target.files[0]);
    }
  };

  const handleUpload = async () => {
    if (!file) {
      toast({
        title: 'No file selected',
        description: 'Please select a file to upload.',
        variant: 'destructive',
      });
      return;
    }

    setUploading(true);
    setUploadProgress(0);

    try {
      // Simulate upload progress (replace with actual API call)
      const progressInterval = setInterval(() => {
        setUploadProgress(prev => {
          if (prev >= 90) {
            clearInterval(progressInterval);
            return 90;
          }
          return prev + 10;
        });
      }, 200);

      // TODO: Replace with actual API call
      // const formData = new FormData();
      // formData.append('file', file);
      // formData.append('notes', notes);
      // formData.append('sha256', sha256 || '');
      //
      // const response = await fetch(`/api-v1/agreements/documents/${documentId}/versions`, {
      //   method: 'POST',
      //   body: formData,
      // });
      //
      // if (!response.ok) {
      //   const error = await response.json();
      //   throw new Error(error.message || 'Upload failed');
      // }

      // Simulated API response
      await new Promise(resolve => setTimeout(resolve, 2000));
      clearInterval(progressInterval);
      setUploadProgress(100);

      toast({
        title: 'Upload successful',
        description: `Version uploaded successfully${sha256 ? ' (de-duplication checked)' : ''}.`,
      });

      onUploadComplete();
      handleClose();
    } catch (error) {
      console.error('Upload error:', error);
      toast({
        title: 'Upload failed',
        description: error instanceof Error ? error.message : 'An error occurred during upload.',
        variant: 'destructive',
      });
    } finally {
      setUploading(false);
      setUploadProgress(0);
    }
  };

  const handleClose = () => {
    setFile(null);
    setNotes('');
    setSha256(null);
    setUploadProgress(0);
    onClose();
  };

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>Upload New Version</DialogTitle>
        </DialogHeader>

        <div className="space-y-4 py-4">
          {/* File Drop Zone */}
          <div className="space-y-2">
            <Label>Document File</Label>
            <div
              className={`border-2 border-dashed rounded-lg p-6 text-center transition-colors ${
                dragActive
                  ? 'border-primary bg-primary/5'
                  : 'border-muted-foreground/25 hover:border-muted-foreground/50'
              }`}
              onDragEnter={handleDrag}
              onDragLeave={handleDrag}
              onDragOver={handleDrag}
              onDrop={handleDrop}
            >
              {file ? (
                <div className="flex items-center justify-center gap-3">
                  <FileText className="h-8 w-8 text-primary" />
                  <div className="text-left">
                    <p className="font-medium">{file.name}</p>
                    <p className="text-sm text-muted-foreground">
                      {(file.size / 1024).toFixed(1)} KB
                    </p>
                  </div>
                </div>
              ) : (
                <div className="space-y-2">
                  <Upload className="h-10 w-10 mx-auto text-muted-foreground" />
                  <div>
                    <p className="font-medium">Drag and drop your file here</p>
                    <p className="text-sm text-muted-foreground">or click to browse</p>
                  </div>
                  <Input
                    type="file"
                    className="hidden"
                    id="file-upload"
                    onChange={handleFileInputChange}
                    accept=".pdf,.docx,.doc,.png,.jpg,.jpeg,.gif,.txt"
                  />
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => document.getElementById('file-upload')?.click()}
                  >
                    Browse Files
                  </Button>
                </div>
              )}
            </div>
            <p className="text-xs text-muted-foreground">
              Supported: PDF, DOCX, DOC, PNG, JPEG, GIF, TXT (max 50MB)
            </p>
          </div>

          {/* SHA-256 Hash Display */}
          {sha256 && (
            <Alert>
              <AlertCircle className="h-4 w-4" />
              <AlertDescription className="font-mono text-xs break-all">
                SHA-256: {sha256.substring(0, 16)}...{sha256.substring(sha256.length - 16)}
              </AlertDescription>
            </Alert>
          )}

          {/* Notes */}
          <div className="space-y-2">
            <Label htmlFor="notes">Notes (Optional)</Label>
            <Textarea
              id="notes"
              placeholder="Add version notes or comments..."
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={3}
              disabled={uploading}
            />
          </div>

          {/* Upload Progress */}
          {uploading && (
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span>Uploading...</span>
                <span>{uploadProgress}%</span>
              </div>
              <Progress value={uploadProgress} />
            </div>
          )}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={handleClose} disabled={uploading}>
            Cancel
          </Button>
          <Button onClick={handleUpload} disabled={!file || uploading}>
            {uploading ? 'Uploading...' : 'Upload Version'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
