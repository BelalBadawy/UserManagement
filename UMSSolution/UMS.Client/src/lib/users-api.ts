import { api } from './api-client';
import type { ApiResponse } from './api-client';

export interface UserResponse {
  id: number;
  fullName: string;
  email: string;
  userName: string;
  isActive: boolean;
  emailConfirmed: boolean;
  phoneNumber: string;
  isLocked: boolean;
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
  isLocked?: boolean | null;
  roleId?: number | null;
}

export interface UserRegistrationRequest {
  fullName: string;
  email: string;
  password?: string;
  confirmPassword?: string;
  phoneNumber: string;
  autoConfirmEmail: boolean;
  activateUser: boolean;
}

export interface UpdateUserRequest {
  userId: number;
  fullName: string;
  phoneNumber: string;
}

export interface UserRoleViewModel {
  roleName: string;
  roleDescription: string;
}

export interface RoleResponse {
  id: number;
  name: string;
  description: string;
}

export const usersApi = {
  getPagedList: (params: PagedFilterRequest): Promise<ApiResponse<PagedResult<UserResponse>>> => {
    const query = new URLSearchParams({
      pageNumber: String(params.pageNumber),
      pageSize: String(params.pageSize),
      ...(params.searchTerm && { searchTerm: params.searchTerm }),
      ...(params.sortBy && { sortBy: params.sortBy }),
      ...(params.sortDirection && { sortDirection: params.sortDirection }),
      ...(params.isActive !== undefined && params.isActive !== null && { isActive: String(params.isActive) }),
      ...(params.isLocked !== undefined && params.isLocked !== null && { isLocked: String(params.isLocked) }),
      ...(params.roleId !== undefined && params.roleId !== null && { roleId: String(params.roleId) }),
    });
    return api.get(`api/v1/users/paged-list?${query.toString()}`);
  },

  register: (data: UserRegistrationRequest): Promise<ApiResponse> => {
    return api.post('api/v1/users/register', data);
  },

  update: (data: UpdateUserRequest): Promise<ApiResponse> => {
    return api.put('api/v1/users/update', data);
  },

  changeStatus: (userId: number, activate: boolean): Promise<ApiResponse> => {
    return api.put('api/v1/users/change-status', {
      userId,
      activateOrDeactivate: activate,
    });
  },

  lock: (userId: number): Promise<ApiResponse> => {
    return api.put('api/v1/users/lock-user', { userId });
  },

  unlock: (userId: number): Promise<ApiResponse> => {
    return api.put('api/v1/users/unlock-user', { userId });
  },

  getUserRoles: (userId: number): Promise<ApiResponse<UserRoleViewModel[]>> => {
    return api.get(`api/v1/users/roles/${userId}`);
  },

  updateUserRoles: (userId: number, roles: string[]): Promise<ApiResponse> => {
    return api.put('api/v1/users/user-roles', { userId, roles });
  },

  getRolesAll: (): Promise<ApiResponse<RoleResponse[]>> => {
    return api.get('api/v1/roles/all');
  },
};
