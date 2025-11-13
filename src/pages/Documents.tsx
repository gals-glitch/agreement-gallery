import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { SidebarProvider, SidebarTrigger } from '@/components/ui/sidebar';
import { AppSidebar } from '@/components/AppSidebar';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { http } from '@/api/http';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { ArrowLeft, FolderOpen, Upload, Download, Eye, History, Search } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { PdfViewerModal } from '@/components/agreementDocs/PdfViewerModal';
import { UploadVersionModal } from '@/components/agreementDocs/UploadVersionModal';
import { VersionsDrawer } from '@/components/agreementDocs/VersionsDrawer';
import { AgreementDocument, AgreementDocumentVersion } from '@/types/agreementDocs';

export default function DocumentsPage() {
  const navigate = useNavigate();

  // Modal states
  const [viewerOpen, setViewerOpen] = useState(false);
  const [uploadOpen, setUploadOpen] = useState(false);
  const [versionsOpen, setVersionsOpen] = useState(false);

  // Selected document state
  const [selectedDocument, setSelectedDocument] = useState<AgreementDocument | null>(null);
  const [selectedVersion, setSelectedVersion] = useState<number>(1);
  const [downloadUrl, setDownloadUrl] = useState<string | null>(null);

  // Filter states
  const [searchText, setSearchText] = useState('');
  const [selectedParty, setSelectedParty] = useState<string>('all');
  const [selectedScope, setSelectedScope] = useState<string>('all');
  const [selectedFund, setSelectedFund] = useState<string>('all');

  // Fetch parties for filter dropdown
  const { data: parties = [] } = useQuery({
    queryKey: ['parties-list'],
    queryFn: async () => {
      const response = await http.get('/parties?limit=1000');
      return response.items || [];
    },
  });

  // Fetch funds for filter dropdown
  const { data: funds = [] } = useQuery({
    queryKey: ['funds-list'],
    queryFn: async () => {
      const response = await http.get('/funds?limit=1000');
      return response.items || [];
    },
  });

  // Fetch documents
  const { data: documents, isLoading, refetch } = useQuery({
    queryKey: ['agreement-documents', searchText, selectedParty, selectedScope, selectedFund],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (searchText) params.append('search', searchText);
      if (selectedParty && selectedParty !== 'all') params.append('party_id', selectedParty);
      if (selectedScope && selectedScope !== 'all') params.append('scope', selectedScope);
      if (selectedFund && selectedFund !== 'all') params.append('fund_id', selectedFund);

      const response = await http.get(`/agreements/documents?${params}`);
      return response;
    },
  });

  // Fetch versions for selected document
  const { data: versions = [] } = useQuery({
    queryKey: ['document-versions', selectedDocument?.id],
    queryFn: async () => {
      if (!selectedDocument) return [];
      const response = await http.get(`/agreements/documents/${selectedDocument.id}/versions`);
      return response;
    },
    enabled: !!selectedDocument,
  });

  const handleViewDocument = async (document: AgreementDocument, version?: number) => {
    setSelectedDocument(document);
    setSelectedVersion(version || document.latest_version);

    // Fetch download URL
    const response = await http.get(`/agreements/documents/${document.id}/download?version=${version || document.latest_version}`);
    setDownloadUrl(response.download_url);

    setViewerOpen(true);
  };

  const handleUploadVersion = (document: AgreementDocument) => {
    setSelectedDocument(document);
    setUploadOpen(true);
  };

  const handleViewVersions = (document: AgreementDocument) => {
    setSelectedDocument(document);
    setVersionsOpen(true);
  };

  const handleVersionChange = async (version: number) => {
    setSelectedVersion(version);

    // Fetch new download URL for selected version
    if (!selectedDocument) return;
    const response = await http.get(`/agreements/documents/${selectedDocument.id}/download?version=${version}`);
    setDownloadUrl(response.download_url);
  };

  const handleDownloadVersion = async (version: number) => {
    if (!selectedDocument) return;

    const response = await http.get(`/agreements/documents/${selectedDocument.id}/download?version=${version}`);
    window.open(response.download_url, '_blank');
  };

  return (
    <SidebarProvider>
      <div className="min-h-screen w-full flex bg-background">
        <AppSidebar />

        <div className="flex-1 flex flex-col">
          <div className="sticky top-0 z-20 bg-background/80 backdrop-blur border-b border-border">
            <div className="px-4 py-3 flex items-center gap-3">
              <SidebarTrigger />
              <Button variant="ghost" size="sm" onClick={() => navigate('/')}>
                <ArrowLeft className="w-4 h-4 mr-2" />
                Back
              </Button>
              <div className="flex items-center gap-2">
                <FolderOpen className="w-5 h-5" />
                <h1 className="text-lg font-semibold">Documents Repository</h1>
              </div>
            </div>
          </div>

          <main className="flex-1 p-6">
            <div className="max-w-7xl mx-auto space-y-6">
              {/* Filters */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Search className="h-5 w-5" />
                    Search & Filters
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                    {/* Text Search */}
                    <div className="space-y-2">
                      <Label htmlFor="search">Search</Label>
                      <Input
                        id="search"
                        placeholder="Search by filename or tags..."
                        value={searchText}
                        onChange={(e) => setSearchText(e.target.value)}
                      />
                    </div>

                    {/* Party Filter */}
                    <div className="space-y-2">
                      <Label htmlFor="party">Party</Label>
                      <Select value={selectedParty} onValueChange={setSelectedParty}>
                        <SelectTrigger>
                          <SelectValue placeholder="All Parties" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="all">All Parties</SelectItem>
                          {parties.map((party: any) => (
                            <SelectItem key={party.id} value={party.id.toString()}>
                              {party.name}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>

                    {/* Scope Filter */}
                    <div className="space-y-2">
                      <Label htmlFor="scope">Scope</Label>
                      <Select value={selectedScope} onValueChange={setSelectedScope}>
                        <SelectTrigger>
                          <SelectValue placeholder="All Scopes" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="all">All Scopes</SelectItem>
                          <SelectItem value="UPFRONT">Upfront</SelectItem>
                          <SelectItem value="DEFERRED">Deferred</SelectItem>
                          <SelectItem value="COMBINED">Combined</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>

                    {/* Fund Filter */}
                    <div className="space-y-2">
                      <Label htmlFor="fund">Fund</Label>
                      <Select value={selectedFund} onValueChange={setSelectedFund}>
                        <SelectTrigger>
                          <SelectValue placeholder="All Funds" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="all">All Funds</SelectItem>
                          {funds.map((fund: any) => (
                            <SelectItem key={fund.id} value={fund.id.toString()}>
                              {fund.name}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* Documents Table */}
              <Card>
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <div>
                      <CardTitle>Agreement Documents</CardTitle>
                      <CardDescription>
                        {documents?.total_count || 0} document{documents?.total_count !== 1 ? 's' : ''} found
                      </CardDescription>
                    </div>
                  </div>
                </CardHeader>
                <CardContent>
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Filename</TableHead>
                        <TableHead>Versions</TableHead>
                        <TableHead>Tags</TableHead>
                        <TableHead>Last Updated</TableHead>
                        <TableHead className="text-right">Actions</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {isLoading ? (
                        <TableRow>
                          <TableCell colSpan={5} className="text-center py-8 text-muted-foreground">
                            Loading documents...
                          </TableCell>
                        </TableRow>
                      ) : !documents?.documents || documents.documents.length === 0 ? (
                        <TableRow>
                          <TableCell colSpan={5} className="text-center py-12">
                            <FolderOpen className="h-12 w-12 mx-auto text-muted-foreground mb-2" />
                            <p className="text-muted-foreground">
                              No documents found. Upload your first document to get started.
                            </p>
                          </TableCell>
                        </TableRow>
                      ) : (
                        documents.documents.map((document) => (
                          <TableRow key={document.id}>
                            <TableCell className="font-medium">{document.filename}</TableCell>
                            <TableCell>
                              <Badge variant="outline">
                                v{document.latest_version}
                              </Badge>
                            </TableCell>
                            <TableCell>
                              <div className="flex gap-1 flex-wrap">
                                {document.tags?.map((tag) => (
                                  <Badge key={tag} variant="secondary" className="text-xs">
                                    {tag}
                                  </Badge>
                                ))}
                              </div>
                            </TableCell>
                            <TableCell>
                              {new Date(document.uploaded_at).toLocaleDateString()}
                            </TableCell>
                            <TableCell className="text-right">
                              <div className="flex justify-end gap-1">
                                <Button
                                  variant="ghost"
                                  size="icon"
                                  onClick={() => handleViewDocument(document)}
                                  title="View PDF"
                                >
                                  <Eye className="h-4 w-4" />
                                </Button>
                                <Button
                                  variant="ghost"
                                  size="icon"
                                  onClick={() => handleUploadVersion(document)}
                                  title="Upload new version"
                                >
                                  <Upload className="h-4 w-4" />
                                </Button>
                                <Button
                                  variant="ghost"
                                  size="icon"
                                  onClick={() => handleViewVersions(document)}
                                  title="View version history"
                                >
                                  <History className="h-4 w-4" />
                                </Button>
                                <Button
                                  variant="ghost"
                                  size="icon"
                                  onClick={() => handleDownloadVersion(document.latest_version)}
                                  title="Download latest version"
                                >
                                  <Download className="h-4 w-4" />
                                </Button>
                              </div>
                            </TableCell>
                          </TableRow>
                        ))
                      )}
                    </TableBody>
                  </Table>
                </CardContent>
              </Card>
            </div>
          </main>
        </div>
      </div>

      {/* Modals */}
      <PdfViewerModal
        open={viewerOpen}
        onClose={() => setViewerOpen(false)}
        document={selectedDocument}
        versions={versions}
        currentVersion={selectedVersion}
        onVersionChange={handleVersionChange}
        downloadUrl={downloadUrl}
      />

      <UploadVersionModal
        open={uploadOpen}
        onClose={() => setUploadOpen(false)}
        documentId={selectedDocument?.id || ''}
        onUploadComplete={() => {
          refetch();
          setUploadOpen(false);
        }}
      />

      <VersionsDrawer
        open={versionsOpen}
        onClose={() => setVersionsOpen(false)}
        versions={versions}
        currentVersion={selectedVersion}
        onVersionSelect={(version) => {
          setVersionsOpen(false);
          handleViewDocument(selectedDocument!, version);
        }}
        onDownload={handleDownloadVersion}
      />
    </SidebarProvider>
  );
}
