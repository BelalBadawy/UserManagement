import { api } from './api-client';
import type { ApiResponse } from './api-client';

export interface CategoryResponse {
  id: number;
  name: string;
  slug: string;
  parentId: number | null;
  sortOrder: number;
  isActive: boolean;
  rowVersion: string;
}

export interface PagedResult<T> {
  data: T[];
  totalCount: number;
  currentPage: number;
  pageSize: number;
}

export interface PagedFilterRequest {
  pageNumber: number;
  pageSize: number;
  searchTerm?: string;
  sortBy?: string;
  sortDirection?: 'asc' | 'desc';
  isActive?: boolean | null;
}

export interface CreateCategoryRequest {
  name: string;
  slug: string;
  parentId: number | null;
  isActive: boolean;
  sortOrder: number;
}

export interface UpdateCategoryRequest {
  id: number;
  name: string;
  slug: string;
  parentId: number | null;
  isActive: boolean;
  sortOrder: number;
  rowVersion: string;
}

export interface CategoryLookupDto {
  id: number;
  name: string;
  parentId: number | null;
}

export const categoriesApi = {
  getPagedList: (params: PagedFilterRequest): Promise<ApiResponse<PagedResult<CategoryResponse>>> => {
    const queryParams: Record<string, string> = {
      pageNumber: String(params.pageNumber),
      pageSize: String(params.pageSize),
    };
    if (params.searchTerm) queryParams.searchTerm = params.searchTerm;
    if (params.sortBy) queryParams.sortBy = params.sortBy;
    if (params.sortDirection) queryParams.sortDirection = params.sortDirection;
    if (params.isActive !== undefined && params.isActive !== null) {
      queryParams.isActive = String(params.isActive);
    }
    const query = new URLSearchParams(queryParams);
    return api.get(`api/v1/categories/paged?${query.toString()}`);
  },

  getAll: (isActive?: boolean): Promise<ApiResponse<CategoryResponse[]>> => {
    const query = isActive !== undefined ? `?isActive=${isActive}` : '';
    return api.get(`api/v1/categories${query}`);
  },

  getForList: (): Promise<ApiResponse<CategoryLookupDto[]>> => {
    return api.get('api/v1/categories/for-list');
  },

  getById: (id: number): Promise<ApiResponse<CategoryResponse>> => {
    return api.get(`api/v1/categories/${id}`);
  },

  create: (data: CreateCategoryRequest): Promise<ApiResponse<number>> => {
    return api.post('api/v1/categories', data);
  },

  update: (data: UpdateCategoryRequest): Promise<ApiResponse> => {
    return api.put('api/v1/categories', data);
  },

  delete: (id: number): Promise<ApiResponse> => {
    return api.delete(`api/v1/categories/${id}`);
  },
};
