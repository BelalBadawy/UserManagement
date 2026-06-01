import { useState, useEffect } from 'react'
import { useSearchParams } from 'react-router-dom'
import { auditLogsApi } from '../lib/audit-logs-api'
import type { AuditTrailResponse } from '../lib/audit-logs-api'
import { useToast } from '../components/ui/toast'
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card'
import { Button } from '../components/ui/button'
import { Badge } from '../components/ui/badge'
import { 
  FileText, 
  Search, 
  ChevronLeft, 
  ChevronRight, 
  ArrowUpDown,
  Calendar,
  Layers,
  Globe,
  Mail,
  SlidersHorizontal,
  X
} from 'lucide-react'
import EntityDiffViewer from '../components/EntityDiffViewer'

export default function AuditLogsManagement() {
  const [searchParams, setSearchParams] = useSearchParams()
  const toast = useToast()

  // State Management
  const [logs, setLogs] = useState<AuditTrailResponse[]>([])
  const [loading, setLoading] = useState(true)
  const [totalCount, setTotalCount] = useState(0)

  // Query Params Synchronized State
  const page = parseInt(searchParams.get('page') || '1')
  const pageSize = 10
  const search = searchParams.get('search') || ''
  const sortBy = searchParams.get('sortBy') || 'datetime'
  const sortDirection = (searchParams.get('sortDirection') || 'desc') as 'asc' | 'desc'

  // Details Sheet State
  const [selectedLog, setSelectedLog] = useState<AuditTrailResponse | null>(null)
  const [sheetOpen, setSheetOpen] = useState(false)

  // Sync controls with URL search params
  const updateUrlParam = (key: string, value: string | null) => {
    const newParams = new URLSearchParams(searchParams)
    if (value) {
      newParams.set(key, value)
    } else {
      newParams.delete(key)
    }
    setSearchParams(newParams)
  }

  // Fetch Audit Logs
  const fetchLogs = async () => {
    setLoading(true)
    try {
      const response = await auditLogsApi.getPagedList({
        pageNumber: page,
        pageSize: pageSize,
        searchTerm: search || undefined,
        sortBy: sortBy,
        sortDirection: sortDirection
      })
      if (response.isSuccessful && response.data) {
        setLogs(response.data.data)
        setTotalCount(response.data.totalCount)
      } else {
        toast.error(response.messages[0] || 'Failed to retrieve audit logs.')
      }
    } catch (err) {
      toast.error('An error occurred while loading audit logs.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchLogs()
  }, [page, search, sortBy, sortDirection])

  // Sorting Handler
  const handleSort = (field: string) => {
    const isAsc = sortBy === field && sortDirection === 'asc'
    updateUrlParam('sortBy', field)
    updateUrlParam('sortDirection', isAsc ? 'desc' : 'asc')
    updateUrlParam('page', '1') // Reset to first page
  }

  // Search Handler
  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    updateUrlParam('search', e.target.value || null)
    updateUrlParam('page', '1') // Reset to page 1 on new search
  }

  // Helper: Audit Type Badge styling
  const renderTypeBadge = (type: string) => {
    switch (type.toLowerCase()) {
      case 'create':
        return <Badge className="bg-emerald-100 hover:bg-emerald-200 text-emerald-800 border-emerald-200 font-bold uppercase text-xs rounded-lg py-1 px-2.5">Create</Badge>
      case 'update':
        return <Badge className="bg-amber-100 hover:bg-amber-200 text-amber-800 border-amber-200 font-bold uppercase text-xs rounded-lg py-1 px-2.5">Update</Badge>
      case 'delete':
        return <Badge className="bg-rose-100 hover:bg-rose-200 text-rose-800 border-rose-200 font-bold uppercase text-xs rounded-lg py-1 px-2.5">Delete</Badge>
      default:
        return <Badge className="bg-blue-100 hover:bg-blue-200 text-blue-800 border-blue-200 font-bold uppercase text-xs rounded-lg py-1 px-2.5">{type}</Badge>
    }
  }

  const totalPages = Math.ceil(totalCount / pageSize)

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold tracking-tight text-neutral-900 flex items-center gap-2">
            <FileText className="w-8 h-8 text-[#4285F4]" /> Audit Logs Directory
          </h1>
          <p className="text-neutral-500 mt-1 text-sm">
            Monitor and audit all creation, update, and deletion actions captured globally.
          </p>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="flex flex-col md:flex-row gap-4 items-center justify-between bg-white p-4 rounded-2xl border border-neutral-200 shadow-xs">
        <div className="relative w-full md:max-w-md">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
          <input
            type="text"
            value={search}
            onChange={handleSearchChange}
            placeholder="Search by Table, Actor Email, or IP Address..."
            className="w-full pl-10 pr-4 py-2 border border-neutral-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4285F4]/30 focus:border-[#4285F4] transition-all bg-neutral-50/50"
          />
        </div>
        <div className="flex items-center gap-2 text-xs text-neutral-400">
          <SlidersHorizontal className="w-3.5 h-3.5" />
          <span>Showing {logs.length} of {totalCount} records</span>
        </div>
      </div>

      {/* Main Grid table */}
      <Card className="rounded-2xl border border-neutral-200 shadow-sm overflow-hidden bg-white">
        <CardHeader className="border-b border-neutral-100 py-4 px-6">
          <CardTitle className="text-lg font-bold text-neutral-900">Activity Log</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-neutral-50/80 border-b border-neutral-200 text-xs font-bold text-neutral-600 uppercase tracking-wider">
                  <th className="py-4 px-6">
                    <button 
                      onClick={() => handleSort('id')} 
                      className="flex items-center gap-1 hover:text-neutral-900 transition-colors"
                    >
                      Log ID <ArrowUpDown className="w-3 h-3" />
                    </button>
                  </th>
                  <th className="py-4 px-6">
                    <button 
                      onClick={() => handleSort('tablename')} 
                      className="flex items-center gap-1 hover:text-neutral-900 transition-colors"
                    >
                      Affected Table <ArrowUpDown className="w-3 h-3" />
                    </button>
                  </th>
                  <th className="py-4 px-6">
                    <button 
                      onClick={() => handleSort('type')} 
                      className="flex items-center gap-1 hover:text-neutral-900 transition-colors"
                    >
                      Event Type <ArrowUpDown className="w-3 h-3" />
                    </button>
                  </th>
                  <th className="py-4 px-6">Actor Email</th>
                  <th className="py-4 px-6">IP Address</th>
                  <th className="py-4 px-6">
                    <button 
                      onClick={() => handleSort('datetime')} 
                      className="flex items-center gap-1 hover:text-neutral-900 transition-colors"
                    >
                      Timestamp <ArrowUpDown className="w-3 h-3" />
                    </button>
                  </th>
                  <th className="py-4 px-6 text-center">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-neutral-100 text-sm text-neutral-700">
                {loading ? (
                  <tr>
                    <td colSpan={7} className="py-12 text-center text-neutral-400">
                      <div className="flex flex-col items-center gap-2">
                        <div className="w-6 h-6 border-2 border-[#4285F4] border-t-transparent rounded-full animate-spin"></div>
                        <span>Loading audit logs...</span>
                      </div>
                    </td>
                  </tr>
                ) : logs.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="py-12 text-center text-neutral-400">
                      No matching audit trails found.
                    </td>
                  </tr>
                ) : (
                  logs.map((log) => (
                    <tr key={log.id} className="hover:bg-neutral-50/50 transition-colors">
                      <td className="py-4 px-6 font-mono text-xs font-semibold text-[#4285F4]">#{log.id}</td>
                      <td className="py-4 px-6 font-bold text-neutral-950 flex items-center gap-1.5">
                        <Layers className="w-3.5 h-3.5 text-neutral-400" />
                        {log.tableName}
                      </td>
                      <td className="py-4 px-6">{renderTypeBadge(log.type)}</td>
                      <td className="py-4 px-6">
                        {log.userEmail ? (
                          <span className="flex items-center gap-1">
                            <Mail className="w-3.5 h-3.5 text-neutral-400" />
                            {log.userEmail}
                          </span>
                        ) : (
                          <span className="text-neutral-400 italic">System / Anonymous</span>
                        )}
                      </td>
                      <td className="py-4 px-6 font-mono text-xs text-neutral-600">
                        {log.ipAddress ? (
                          <span className="flex items-center gap-1">
                            <Globe className="w-3.5 h-3.5 text-neutral-400" />
                            {log.ipAddress}
                          </span>
                        ) : (
                          <span className="text-neutral-400">-</span>
                        )}
                      </td>
                      <td className="py-4 px-6">
                        <span className="flex items-center gap-1 text-neutral-600 text-xs">
                          <Calendar className="w-3.5 h-3.5 text-neutral-400" />
                          {new Date(log.dateTime).toLocaleString()}
                        </span>
                      </td>
                      <td className="py-4 px-6 text-center">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => {
                            setSelectedLog(log)
                            setSheetOpen(true)
                          }}
                          className="h-8 border-[#4285F4]/30 text-[#4285F4] hover:bg-[#4285F4]/5 font-semibold text-xs rounded-xl"
                        >
                          View Details
                        </Button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          {/* Pagination Controls */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between border-t border-neutral-100 px-6 py-4 bg-neutral-50/50">
              <span className="text-xs text-neutral-400">
                Page {page} of {totalPages} ({totalCount} total logs)
              </span>
              <div className="flex items-center gap-2">
                <Button
                  variant="outline"
                  size="icon"
                  disabled={page <= 1}
                  onClick={() => updateUrlParam('page', String(page - 1))}
                  className="w-8 h-8 rounded-lg"
                >
                  <ChevronLeft className="w-4 h-4" />
                </Button>
                {Array.from({ length: totalPages }, (_, i) => i + 1)
                  .filter((p) => Math.abs(p - page) <= 1 || p === 1 || p === totalPages)
                  .map((p, idx, arr) => {
                    const prev = arr[idx - 1]
                    const showEllipsis = prev && p - prev > 1
                    return (
                      <div key={p} className="flex items-center gap-1">
                        {showEllipsis && <span className="text-neutral-400 text-xs px-1">...</span>}
                        <Button
                          variant={page === p ? 'default' : 'outline'}
                          onClick={() => updateUrlParam('page', String(p))}
                          className={`w-8 h-8 rounded-lg text-xs font-bold ${page === p ? 'bg-[#4285F4] hover:bg-[#3273DC]' : ''}`}
                        >
                          {p}
                        </Button>
                      </div>
                    )
                  })}
                <Button
                  variant="outline"
                  size="icon"
                  disabled={page >= totalPages}
                  onClick={() => updateUrlParam('page', String(page + 1))}
                  className="w-8 h-8 rounded-lg"
                >
                  <ChevronRight className="w-4 h-4" />
                </Button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* --- DETAILS SIDE SHEET PANEL --- */}
      {sheetOpen && selectedLog && (
        <div className="fixed inset-0 z-50 animate-in fade-in duration-200">
          {/* Backdrop */}
          <div 
            className="fixed inset-0 bg-black/40 backdrop-blur-xs" 
            onClick={() => setSheetOpen(false)} 
          />
          {/* Content Pane */}
          <div className="fixed top-0 right-0 bottom-0 w-full md:w-3/5 max-w-3xl bg-white border-l border-neutral-200 shadow-2xl p-6 flex flex-col z-50 animate-in slide-in-from-right duration-250">
            
            {/* Header */}
            <div className="flex items-center justify-between pb-4 border-b border-neutral-100">
              <div>
                <h2 className="text-xl font-extrabold text-neutral-900 flex items-center gap-2">
                  <FileText className="w-5 h-5 text-[#4285F4]" /> Audit Log details
                </h2>
                <p className="text-xs text-[#4285F4] font-mono mt-1 font-semibold">Log ID: #{selectedLog.id}</p>
              </div>
              <Button
                variant="ghost"
                size="icon"
                onClick={() => setSheetOpen(false)}
                className="h-9 w-9 text-neutral-500 hover:bg-neutral-100 rounded-lg"
              >
                <X className="w-5 h-5" />
              </Button>
            </div>

            {/* Scrollable details */}
            <div className="flex-1 overflow-y-auto py-6 space-y-6 pr-1">
              
              {/* Log Metadata Grid */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 bg-neutral-50 p-4 rounded-2xl border border-neutral-200 text-sm">
                <div>
                  <span className="text-xs text-neutral-400 uppercase tracking-wider block">Affected Table</span>
                  <span className="font-bold text-neutral-900">{selectedLog.tableName}</span>
                </div>
                <div>
                  <span className="text-xs text-neutral-400 uppercase tracking-wider block">Event Type</span>
                  <span className="mt-0.5 inline-block">{renderTypeBadge(selectedLog.type)}</span>
                </div>
                <div>
                  <span className="text-xs text-neutral-400 uppercase tracking-wider block">Actor Email</span>
                  <span className="font-medium text-neutral-900">
                    {selectedLog.userEmail || 'System / Anonymous'}
                  </span>
                </div>
                <div>
                  <span className="text-xs text-neutral-400 uppercase tracking-wider block">IP Address</span>
                  <span className="font-mono text-xs font-medium text-neutral-900">
                    {selectedLog.ipAddress || '-'}
                  </span>
                </div>
                <div className="sm:col-span-2">
                  <span className="text-xs text-neutral-400 uppercase tracking-wider block">Primary Key (Identifier)</span>
                  <span className="font-mono text-xs text-neutral-800 break-all">
                    {selectedLog.primaryKey || 'None'}
                  </span>
                </div>
              </div>

              {/* Old vs New Values JSON Viewers */}
              <div className="space-y-4">
                {selectedLog.affectedColumns && (
                  <div>
                    <h3 className="text-xs font-bold text-neutral-400 uppercase tracking-wider mb-2">Affected Columns</h3>
                    <div className="flex flex-wrap gap-1.5">
                      {JSON.parse(selectedLog.affectedColumns).map((col: string) => (
                        <Badge key={col} variant="outline" className="text-xs bg-neutral-50 font-semibold">{col}</Badge>
                      ))}
                    </div>
                  </div>
                )}

                <EntityDiffViewer 
                  oldValues={selectedLog.oldValues} 
                  newValues={selectedLog.newValues} 
                />
              </div>

            </div>

            {/* Footer */}
            <div className="pt-4 border-t border-neutral-100 flex justify-end">
              <Button
                onClick={() => setSheetOpen(false)}
                className="bg-neutral-900 hover:bg-neutral-800 text-white rounded-xl px-6"
              >
                Close Panel
              </Button>
            </div>

          </div>
        </div>
      )}
    </div>
  )
}
