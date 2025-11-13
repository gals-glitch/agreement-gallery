import React from 'react';
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetDescription,
} from '@/components/ui/sheet';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Download, FileText, Clock } from 'lucide-react';
import { AgreementDocumentVersion, formatFileSize, formatDate } from '@/types/agreementDocs';
import { Separator } from '@/components/ui/separator';

interface VersionsDrawerProps {
  open: boolean;
  onClose: () => void;
  versions: AgreementDocumentVersion[];
  currentVersion?: number;
  onVersionSelect: (version: number) => void;
  onDownload: (version: number) => void;
}

export function VersionsDrawer({
  open,
  onClose,
  versions,
  currentVersion,
  onVersionSelect,
  onDownload,
}: VersionsDrawerProps) {
  // Sort versions descending (latest first)
  const sortedVersions = [...versions].sort((a, b) => b.version_number - a.version_number);

  return (
    <Sheet open={open} onOpenChange={onClose}>
      <SheetContent side="right" className="w-[400px] sm:w-[540px]">
        <SheetHeader>
          <SheetTitle>Document Versions</SheetTitle>
          <SheetDescription>
            {versions.length} version{versions.length !== 1 ? 's' : ''} available
          </SheetDescription>
        </SheetHeader>

        <div className="mt-6 space-y-4">
          {sortedVersions.map((version, index) => {
            const isLatest = index === 0;
            const isCurrent = version.version_number === currentVersion;

            return (
              <div key={version.version_number}>
                <div
                  className={`p-4 rounded-lg border transition-colors ${
                    isCurrent
                      ? 'border-primary bg-primary/5'
                      : 'border-border hover:bg-muted/50'
                  }`}
                >
                  {/* Version Header */}
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex items-center gap-2">
                      <FileText className="h-5 w-5 text-muted-foreground" />
                      <div>
                        <div className="flex items-center gap-2">
                          <h4 className="font-semibold">Version {version.version_number}</h4>
                          {isLatest && (
                            <Badge variant="default" className="text-xs">
                              Latest
                            </Badge>
                          )}
                          {isCurrent && !isLatest && (
                            <Badge variant="outline" className="text-xs">
                              Viewing
                            </Badge>
                          )}
                        </div>
                        <p className="text-sm text-muted-foreground mt-1">
                          {version.filename}
                        </p>
                      </div>
                    </div>
                  </div>

                  {/* Version Metadata */}
                  <div className="space-y-2 text-sm mb-3">
                    <div className="flex items-center gap-2 text-muted-foreground">
                      <Clock className="h-3.5 w-3.5" />
                      <span>
                        {formatDate(version.uploaded_at)} by{' '}
                        {version.uploaded_by_name || 'Unknown'}
                      </span>
                    </div>

                    <div className="flex items-center gap-4">
                      <span className="text-muted-foreground">
                        Size: {formatFileSize(version.file_size_bytes)}
                      </span>
                      <span className="text-muted-foreground">
                        Type: {version.mime_type.split('/')[1].toUpperCase()}
                      </span>
                    </div>
                  </div>

                  {/* Notes */}
                  {version.notes && (
                    <div className="mb-3 p-2 rounded bg-muted/50 text-sm">
                      <p className="text-muted-foreground italic">{version.notes}</p>
                    </div>
                  )}

                  {/* Actions */}
                  <div className="flex items-center gap-2">
                    <Button
                      variant={isCurrent ? 'default' : 'outline'}
                      size="sm"
                      onClick={() => onVersionSelect(version.version_number)}
                      className="flex-1"
                    >
                      {isCurrent ? 'Viewing' : 'View'}
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => onDownload(version.version_number)}
                      title="Download this version"
                    >
                      <Download className="h-4 w-4" />
                    </Button>
                  </div>
                </div>

                {/* Separator between versions */}
                {index < sortedVersions.length - 1 && <Separator className="my-4" />}
              </div>
            );
          })}

          {/* Empty State */}
          {versions.length === 0 && (
            <div className="text-center py-12">
              <FileText className="h-12 w-12 mx-auto text-muted-foreground mb-3" />
              <p className="text-muted-foreground">No versions found</p>
            </div>
          )}
        </div>
      </SheetContent>
    </Sheet>
  );
}
