import { api } from './api-client';
import type { ApiResponse } from './api-client';
import type { PagedResult } from './categories-api';

export interface AuditTrailResponse {
  id: number;
  userId: number | null;
  userEmail: string | null;
  ipAddress: string | null;
  type: string;
  tableName: string | null;
  dateTime: string;
  oldValues: string | null;
  newValues: string | null;
  affectedColumns: string | null;
  primaryKey: string | null;
}

export interface AuditLogsFilterRequest {
  pageNumber: number;
  pageSize: number;
  searchTerm?: string;
  sortBy?: string;
  sortDirection?: 'asc' | 'desc';
}

export const auditLogsApi = {
  getPagedList: (params: AuditLogsFilterRequest): Promise<ApiResponse<PagedResult<AuditTrailResponse>>> => {
    const queryParams: Record<string, string> = {
      pageNumber: String(params.pageNumber),
      pageSize: String(params.pageSize),
    };
    if (params.searchTerm) queryParams.searchTerm = params.searchTerm;
    if (params.sortBy) queryParams.sortBy = params.sortBy;
    if (params.sortDirection) queryParams.sortDirection = params.sortDirection;
    const query = new URLSearchParams(queryParams);
    return api.get(`api/v1/audit-logs?${query.toString()}`);
  }
};
