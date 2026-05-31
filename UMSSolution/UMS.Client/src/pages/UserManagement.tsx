import React, { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useAuth } from '../components/AuthContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { Button } from '../components/ui/button';
import { Badge } from '../components/ui/badge';
import { useToast } from '../components/ui/toast';
import { Sheet, SheetHeader, SheetTitle, SheetDescription, SheetFooter } from '../components/ui/sheet';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter, DialogClose } from '../components/ui/dialog';
import { PasswordStrengthMeter } from '../components/PasswordStrengthMeter';
import { usersApi } from '../lib/users-api';
import type { UserResponse, RoleResponse } from '../lib/users-api';
import { 
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue 
} from '../components/ui/select';
import {
  Pagination, PaginationContent, PaginationEllipsis, PaginationItem,
  PaginationLink, PaginationNext, PaginationPrevious
} from '../components/ui/pagination';
import { 
  Plus, Edit2, Trash2, UserCheck, AlertTriangle, 
  Search, RotateCcw, Lock, Unlock, Loader2 
} from 'lucide-react';

export default function UserManagement() {
  const { hasPermission } = useAuth();
  const toast = useToast();

  // List States
  const [users, setUsers] = useState<UserResponse[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [availableRoles, setAvailableRoles] = useState<RoleResponse[]>([]);

  // Query / Filter / Pagination States
  const [searchParams, setSearchParams] = useSearchParams();

  const pageNumber = parseInt(searchParams.get('page') || '1', 10);
  const searchTerm = searchParams.get('search') || '';
  const activeParam = searchParams.get('active') || 'all';
  const lockedParam = searchParams.get('locked') || 'all';
  const roleParam = searchParams.get('role') || 'all';

  const [searchInput, setSearchInput] = useState(searchTerm);
  const [pageSize] = useState(10);
  const [sortBy, setSortBy] = useState('fullname');
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('asc');

  // Sync search input if searchTerm changes (e.g. from reset or back navigation)
  useEffect(() => {
    setSearchInput(searchTerm);
  }, [searchTerm]);

  const updateFilters = (newParams: Record<string, string | null>) => {
    const nextParams = new URLSearchParams(searchParams);
    
    // Changing filters or searching resets to page 1
    if (newParams.page === undefined && (newParams.search !== undefined || newParams.active !== undefined || newParams.locked !== undefined || newParams.role !== undefined)) {
      nextParams.set('page', '1');
    }

    Object.entries(newParams).forEach(([key, val]) => {
      if (val === null || val === 'all' || (key === 'page' && val === '1') || (key === 'search' && val === '')) {
        nextParams.delete(key);
      } else {
        nextParams.set(key, val);
      }
    });

    setSearchParams(nextParams);
  };

  // Dialog & Sheet States
  const [isFormSheetOpen, setIsFormSheetOpen] = useState(false);
  const [isConfirmDialogOpen, setIsConfirmDialogOpen] = useState(false);
  const [confirmAction, setConfirmAction] = useState<'lock' | 'unlock' | 'delete' | 'activate' | 'deactivate' | null>(null);
  const [targetUser, setTargetUser] = useState<UserResponse | null>(null);
  
  // Form States
  const [formMode, setFormMode] = useState<'create' | 'edit'>('create');
  const [formFullName, setFormFullName] = useState('');
  const [formEmail, setFormEmail] = useState('');
  const [formPhoneNumber, setFormPhoneNumber] = useState('');
  const [formPassword, setFormPassword] = useState('');
  const [formConfirmPassword, setFormConfirmPassword] = useState('');
  const [formActivateUser, setFormActivateUser] = useState(true);
  const [formAutoConfirmEmail, setFormAutoConfirmEmail] = useState(false);
  const [formRoles, setFormRoles] = useState<string[]>([]);
  const [formSubmitting, setFormSubmitting] = useState(false);

  // Validation States
  const [errors, setErrors] = useState<Record<string, string>>({});

  // Map user ID to their roles for visual rendering
  const [userRolesMap, setUserRolesMap] = useState<Record<number, string[]>>({});

  // Load available roles on mount
  useEffect(() => {
    const fetchRoles = async () => {
      try {
        const response = await usersApi.getRolesAll();
        if (response.isSuccessful && response.data) {
          setAvailableRoles(response.data);
        }
      } catch (err) {
        console.error('Failed to load roles', err);
      }
    };
    fetchRoles();
  }, []);

  // Fetch users paged list
  const fetchUsers = async () => {
    setLoading(true);
    try {
      let isActive: boolean | null = null;
      if (activeParam === 'active') isActive = true;
      if (activeParam === 'inactive') isActive = false;

      let isLocked: boolean | null = null;
      if (lockedParam === 'locked') isLocked = true;
      if (lockedParam === 'unlocked') isLocked = false;

      const roleId = roleParam !== 'all' ? parseInt(roleParam, 10) : null;

      const response = await usersApi.getPagedList({
        pageNumber,
        pageSize,
        searchTerm,
        sortBy,
        sortDirection,
        isActive,
        isLocked,
        roleId,
      });

      if (response.isSuccessful && response.data) {
        setUsers(response.data.data);
        setTotalCount(response.data.totalCount);

        // Fetch roles for each user in parallel to render in the table
        const rolesPromises = response.data.data.map(async (u) => {
          try {
            const roleResponse = await usersApi.getUserRoles(u.id);
            if (roleResponse.isSuccessful && roleResponse.data) {
              return { userId: u.id, roles: roleResponse.data.map(r => r.roleName) };
            }
          } catch (e) {
            console.error(`Failed to fetch roles for user ${u.id}`, e);
          }
          return { userId: u.id, roles: [] };
        });

        const results = await Promise.all(rolesPromises);
        const nextMap: Record<number, string[]> = {};
        results.forEach(res => {
          nextMap[res.userId] = res.roles;
        });
        setUserRolesMap(nextMap);
      } else {
        toast.error(response.messages[0] || 'Failed to retrieve users.');
      }
    } catch (err) {
      console.error(err);
      toast.error('An error occurred while loading users.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [pageNumber, pageSize, searchTerm, activeParam, lockedParam, roleParam, sortBy, sortDirection]);

  // Handle Searches
  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    updateFilters({ search: searchInput });
  };

  const handleResetFilters = () => {
    setSearchInput('');
    updateFilters({
      page: '1',
      search: '',
      active: 'all',
      locked: 'all',
      role: 'all'
    });
    setSortBy('fullname');
    setSortDirection('asc');
  };

  // Toggle Sorting
  const toggleSort = (field: string) => {
    if (sortBy === field) {
      setSortDirection(prev => (prev === 'asc' ? 'desc' : 'asc'));
    } else {
      setSortBy(field);
      setSortDirection('asc');
    }
  };

  // Form Validation
  const validateForm = () => {
    const nextErrors: Record<string, string> = {};

    if (!formFullName.trim()) {
      nextErrors.fullName = 'Full Name is required';
    } else if (formFullName.trim().length < 3) {
      nextErrors.fullName = 'Full Name must be at least 3 characters';
    }

    if (formMode === 'create') {
      if (!formEmail.trim()) {
        nextErrors.email = 'Email is required';
      } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formEmail)) {
        nextErrors.email = 'Please enter a valid email address';
      }

      if (!formPassword) {
        nextErrors.password = 'Password is required';
      } else {
        // Password strength complexity validation
        const hasMinLength = formPassword.length >= 6;
        const hasUpper = /[A-Z]/.test(formPassword);
        const hasLower = /[a-z]/.test(formPassword);
        const hasNumber = /\d/.test(formPassword);
        const hasSpecial = /[^a-zA-Z0-9]/.test(formPassword);

        if (!hasMinLength || !hasUpper || !hasLower || !hasNumber || !hasSpecial) {
          nextErrors.password = 'Password is too weak';
        }
      }

      if (formPassword !== formConfirmPassword) {
        nextErrors.confirmPassword = 'Passwords do not match';
      }
    }

    if (!formPhoneNumber.trim()) {
      nextErrors.phoneNumber = 'Phone Number is required';
    } else if (!/^[0-9+\s-]{7,15}$/.test(formPhoneNumber)) {
      nextErrors.phoneNumber = 'Invalid phone number format';
    }

    setErrors(nextErrors);
    return Object.keys(nextErrors).length === 0;
  };

  // Open Create Form
  const openCreateSheet = () => {
    setFormMode('create');
    setFormFullName('');
    setFormEmail('');
    setFormPhoneNumber('');
    setFormPassword('');
    setFormConfirmPassword('');
    setFormActivateUser(true);
    setFormAutoConfirmEmail(false);
    setFormRoles(['Basic']);
    setErrors({});
    setIsFormSheetOpen(true);
  };

  // Open Edit Form
  const openEditSheet = async (user: UserResponse) => {
    setFormMode('edit');
    setTargetUser(user);
    setFormFullName(user.fullName);
    setFormEmail(user.email);
    setFormPhoneNumber(user.phoneNumber);
    setFormRoles(userRolesMap[user.id] || []);
    setErrors({});
    setIsFormSheetOpen(true);
  };

  // Submit User creation/edit Form
  const handleSubmitUser = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateForm()) return;

    setFormSubmitting(true);
    try {
      if (formMode === 'create') {
        const response = await usersApi.register({
          fullName: formFullName,
          email: formEmail,
          password: formPassword,
          confirmPassword: formConfirmPassword,
          phoneNumber: formPhoneNumber,
          activateUser: formActivateUser,
          autoConfirmEmail: formAutoConfirmEmail,
        });

        if (response.isSuccessful) {
          toast.success('User created successfully!');
          setIsFormSheetOpen(false);
          fetchUsers();
        } else {
          toast.error(response.messages[0] || 'Registration failed.');
        }
      } else {
        // Edit Flow
        if (!targetUser) return;
        const profileRes = await usersApi.update({
          userId: targetUser.id,
          fullName: formFullName,
          phoneNumber: formPhoneNumber,
        });

        if (profileRes.isSuccessful) {
          // Update assigned roles
          const rolesRes = await usersApi.updateUserRoles(targetUser.id, formRoles);
          if (rolesRes.isSuccessful) {
            toast.success('User details and roles updated successfully!');
            setIsFormSheetOpen(false);
            fetchUsers();
          } else {
            toast.warning('User details updated, but role assignment failed: ' + rolesRes.messages[0]);
          }
        } else {
          toast.error(profileRes.messages[0] || 'Failed to update user details.');
        }
      }
    } catch (err) {
      console.error(err);
      toast.error('An error occurred during form submission.');
    } finally {
      setFormSubmitting(false);
    }
  };

  // Role selections toggle helper
  const handleRoleToggle = (roleName: string) => {
    setFormRoles(prev => 
      prev.includes(roleName) 
        ? prev.filter(r => r !== roleName) 
        : [...prev, roleName]
    );
  };

  // Open Actions Confirmation Modal
  const requestConfirm = (action: 'lock' | 'unlock' | 'delete' | 'activate' | 'deactivate', user: UserResponse) => {
    setConfirmAction(action);
    setTargetUser(user);
    setIsConfirmDialogOpen(true);
  };

  // Execute lock/unlock/delete/activate/deactivate operations
  const executeConfirmAction = async () => {
    if (!targetUser || !confirmAction) return;

    try {
      if (confirmAction === 'lock') {
        const res = await usersApi.lock(targetUser.id);
        if (res.isSuccessful) {
          toast.success(`User "${targetUser.fullName}" locked successfully.`);
          fetchUsers();
        } else {
          toast.error(res.messages[0] || 'Failed to lock user.');
        }
      } else if (confirmAction === 'unlock') {
        const res = await usersApi.unlock(targetUser.id);
        if (res.isSuccessful) {
          toast.success(`User "${targetUser.fullName}" unlocked successfully.`);
          fetchUsers();
        } else {
          toast.error(res.messages[0] || 'Failed to unlock user.');
        }
      } else if (confirmAction === 'activate') {
        const res = await usersApi.changeStatus(targetUser.id, true);
        if (res.isSuccessful) {
          toast.success(`User "${targetUser.fullName}" activated successfully.`);
          fetchUsers();
        } else {
          toast.error(res.messages[0] || 'Failed to activate user.');
        }
      } else if (confirmAction === 'deactivate') {
        const res = await usersApi.changeStatus(targetUser.id, false);
        if (res.isSuccessful) {
          toast.success(`User "${targetUser.fullName}" deactivated successfully.`);
          fetchUsers();
        } else {
          toast.error(res.messages[0] || 'Failed to deactivate user.');
        }
      } else if (confirmAction === 'delete') {
        // simulated delete operation
        toast.success(`Delete operation simulated successfully for user "${targetUser.fullName}"! (Verified claim: Permission.Identity.Users.Delete)`);
      }
    } catch (err) {
      console.error(err);
      toast.error('Operation failed.');
    } finally {
      setIsConfirmDialogOpen(false);
      setConfirmAction(null);
      setTargetUser(null);
    }
  };

  const totalPages = Math.ceil(totalCount / pageSize);

  return (
    <div className="space-y-6">
      
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-3xl font-extrabold tracking-tight text-neutral-900">User Management</h1>
          <p className="text-sm text-neutral-500 mt-1">Search, lock, unlock, and manage system user records.</p>
        </div>

        {/* Create User Button Guarded by hasPermission */}
        {hasPermission('Permission.Identity.Users.Create') ? (
          <Button onClick={openCreateSheet} className="bg-[#4285F4] hover:bg-[#3273DC] text-white font-bold py-2.5 px-5 rounded-xl shadow-sm flex items-center gap-2 transition-all">
            <Plus className="w-4 h-4" />
            Create User
          </Button>
        ) : (
          <div className="text-xs text-amber-600 bg-amber-50 border border-amber-100 p-2.5 rounded-xl font-medium flex items-center gap-1.5 max-w-xs leading-tight">
            <AlertTriangle className="w-4 h-4 shrink-0 text-amber-500" />
            <span>Creation disabled due to insufficient permissions.</span>
          </div>
        )}
      </div>

      {/* Search & Filters */}
      <Card className="bg-white border-neutral-200 shadow-sm rounded-xl">
        <CardContent className="p-4">
          <form onSubmit={handleSearchSubmit} className="flex flex-col md:flex-row gap-3">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-neutral-400" />
              <input
                type="text"
                placeholder="Search by full name or email..."
                value={searchInput}
                onChange={(e) => setSearchInput(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-neutral-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4285F4]/30 focus:border-[#4285F4] bg-neutral-50/50"
              />
            </div>
            <div className="flex gap-2 shrink-0">
              <Button type="submit" variant="default" className="rounded-xl px-5">
                Search
              </Button>
              <Button type="button" variant="outline" onClick={handleResetFilters} className="rounded-xl px-4 flex items-center gap-1">
                <RotateCcw className="w-3.5 h-3.5" />
                Reset
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      {/* Advanced Filter Bar */}
      <div className="flex flex-wrap items-center gap-4 bg-white border border-neutral-200 shadow-sm rounded-xl p-4">
        {/* Status Filter */}
        <div className="flex flex-col gap-1.5">
          <span className="text-xs font-semibold text-neutral-500 uppercase tracking-wider">Status</span>
          <Select value={activeParam} onValueChange={(val) => updateFilters({ active: val })}>
            <SelectTrigger className="w-[160px] h-9 border-neutral-200 rounded-xl bg-neutral-50/30 focus:ring-[#4285F4]/30">
              <SelectValue placeholder="All" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All</SelectItem>
              <SelectItem value="active">Active</SelectItem>
              <SelectItem value="inactive">Inactive</SelectItem>
            </SelectContent>
          </Select>
        </div>

        {/* Lockout Filter */}
        <div className="flex flex-col gap-1.5">
          <span className="text-xs font-semibold text-neutral-500 uppercase tracking-wider">Lockout</span>
          <Select value={lockedParam} onValueChange={(val) => updateFilters({ locked: val })}>
            <SelectTrigger className="w-[160px] h-9 border-neutral-200 rounded-xl bg-neutral-50/30 focus:ring-[#4285F4]/30">
              <SelectValue placeholder="All" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All</SelectItem>
              <SelectItem value="locked">Locked</SelectItem>
              <SelectItem value="unlocked">Unlocked</SelectItem>
            </SelectContent>
          </Select>
        </div>

        {/* Role Filter */}
        <div className="flex flex-col gap-1.5">
          <span className="text-xs font-semibold text-neutral-500 uppercase tracking-wider">Assigned Role</span>
          <Select value={roleParam} onValueChange={(val) => updateFilters({ role: val })}>
            <SelectTrigger className="w-[200px] h-9 border-neutral-200 rounded-xl bg-neutral-50/30 focus:ring-[#4285F4]/30">
              <SelectValue placeholder="All Roles" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Roles</SelectItem>
              {availableRoles.map((role) => (
                <SelectItem key={role.id} value={String(role.id)}>
                  {role.name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      </div>

      {/* Main Table Card */}
      <Card className="bg-white border border-neutral-200 shadow-xl rounded-2xl overflow-hidden">
        <CardHeader className="border-b border-neutral-100 pb-4 bg-neutral-50/30">
          <div className="flex justify-between items-center">
            <div>
              <CardTitle className="text-lg font-bold text-neutral-900">System Users</CardTitle>
              <CardDescription>A paginated overview of system accounts.</CardDescription>
            </div>
            <div className="text-xs font-semibold text-neutral-400">
              Total Records: {totalCount}
            </div>
          </div>
        </CardHeader>

        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-neutral-200 bg-neutral-50/50 text-neutral-500 text-xs font-bold uppercase tracking-wider">
                  <th onClick={() => toggleSort('fullname')} className="px-6 py-4 cursor-pointer hover:bg-neutral-100 select-none transition-colors">
                    User {sortBy === 'fullname' && (sortDirection === 'asc' ? '▲' : '▼')}
                  </th>
                  <th onClick={() => toggleSort('email')} className="px-6 py-4 cursor-pointer hover:bg-neutral-100 select-none transition-colors">
                    Email {sortBy === 'email' && (sortDirection === 'asc' ? '▲' : '▼')}
                  </th>
                  <th className="px-6 py-4">Assigned Roles</th>
                  <th className="px-6 py-4">Status</th>
                  <th className="px-6 py-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-neutral-100 text-sm text-neutral-800">
                {loading ? (
                  <tr>
                    <td colSpan={5} className="text-center py-12 text-neutral-400">
                      <div className="flex items-center justify-center gap-2">
                        <Loader2 className="w-5 h-5 animate-spin text-[#4285F4]" />
                        <span>Loading user directory...</span>
                      </div>
                    </td>
                  </tr>
                ) : users.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="text-center py-12 text-neutral-400">
                      No matching user accounts found.
                    </td>
                  </tr>
                ) : (
                  users.map((usr) => {
                    const isUserAdmin = userRolesMap[usr.id]?.some(r => r.toLowerCase() === 'admin');
                    return (
                      <tr key={usr.id} className="hover:bg-neutral-50/50 transition-colors">
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-3">
                            <div className="w-9 h-9 rounded-full bg-neutral-100 text-neutral-600 font-bold flex items-center justify-center text-xs border border-neutral-200">
                              {usr.fullName[0]?.toUpperCase() || '?'}
                            </div>
                            <div>
                              <div className="font-bold text-neutral-900">{usr.fullName}</div>
                              <div className="text-xs text-neutral-400 font-medium">#{usr.id} · {usr.phoneNumber || 'No phone'}</div>
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4 font-medium text-neutral-600">
                          {usr.email}
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex flex-wrap gap-1">
                            {userRolesMap[usr.id]?.length ? (
                              userRolesMap[usr.id].map(r => (
                                <Badge key={r} variant="secondary" className="bg-[#4285F4]/10 text-[#4285F4] hover:bg-[#4285F4]/20 border-transparent text-xs font-semibold px-2 py-0.5 rounded">
                                  {r}
                                </Badge>
                              ))
                            ) : (
                              <span className="text-xs text-neutral-400 italic">None</span>
                            )}
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex flex-col gap-1 items-start">
                            <div className="flex flex-wrap gap-1">
                              <Badge 
                                variant={usr.isActive ? "default" : "secondary"}
                                className={
                                  usr.isActive 
                                    ? 'bg-emerald-500 hover:bg-emerald-600 text-white font-bold' 
                                    : 'bg-neutral-200 text-neutral-600 hover:bg-neutral-300 font-bold'
                                }
                              >
                                {usr.isActive ? 'Active' : 'Inactive'}
                              </Badge>
                              {usr.isLocked && (
                                <Badge 
                                  className="bg-amber-500 hover:bg-amber-600 text-white font-bold border-transparent"
                                >
                                  Locked
                                </Badge>
                              )}
                            </div>
                            {usr.emailConfirmed && (
                              <span className="text-[10px] text-emerald-600 font-semibold bg-emerald-50 border border-emerald-100 rounded px-1">Email Verified</span>
                            )}
                          </div>
                        </td>
                        <td className="px-6 py-4 text-right">
                          <div className="flex items-center justify-end gap-1.5">
                            {/* Lock / Unlock Toggle buttons */}
                            {usr.isLocked ? (
                              hasPermission('Permission.Identity.Users.Unlock') && !isUserAdmin && (
                                <Button 
                                  variant="ghost" 
                                  size="icon" 
                                  onClick={() => requestConfirm('unlock', usr)}
                                  className="h-8 w-8 text-emerald-500 hover:text-emerald-700 hover:bg-emerald-50 rounded-lg"
                                  title="Unlock User Account"
                                >
                                  <Unlock className="w-3.5 h-3.5" />
                                </Button>
                              )
                            ) : (
                              hasPermission('Permission.Identity.Users.Lock') && !isUserAdmin && (
                                <Button 
                                  variant="ghost" 
                                  size="icon" 
                                  onClick={() => requestConfirm('lock', usr)}
                                  className="h-8 w-8 text-amber-500 hover:text-amber-700 hover:bg-amber-50 rounded-lg"
                                  title="Lock User Account"
                                >
                                  <Lock className="w-3.5 h-3.5" />
                                </Button>
                              )
                            )}

                            {/* Active / Inactive Status Toggle buttons */}
                            {usr.isActive ? (
                              hasPermission('Permission.Identity.Users.Update') && !isUserAdmin && (
                                <Button 
                                  variant="ghost" 
                                  size="icon" 
                                  onClick={() => requestConfirm('deactivate', usr)}
                                  className="h-8 w-8 text-rose-500 hover:text-rose-700 hover:bg-rose-50 rounded-lg"
                                  title="Deactivate User Account"
                                >
                                  <UserCheck className="w-3.5 h-3.5 text-neutral-400" />
                                </Button>
                              )
                            ) : (
                              hasPermission('Permission.Identity.Users.Update') && !isUserAdmin && (
                                <Button 
                                  variant="ghost" 
                                  size="icon" 
                                  onClick={() => requestConfirm('activate', usr)}
                                  className="h-8 w-8 text-emerald-500 hover:text-emerald-700 hover:bg-emerald-50 rounded-lg"
                                  title="Activate User Account"
                                >
                                  <UserCheck className="w-3.5 h-3.5 text-emerald-500" />
                                </Button>
                              )
                            )}

                            {/* Edit User Button - Guarded */}
                            {hasPermission('Permission.Identity.Users.Update') && (
                              <Button 
                                variant="ghost" 
                                size="icon" 
                                onClick={() => openEditSheet(usr)}
                                className="h-8 w-8 text-neutral-500 hover:text-neutral-900 hover:bg-neutral-100 rounded-lg"
                                title="Edit Details & Roles"
                              >
                                <Edit2 className="w-3.5 h-3.5" />
                              </Button>
                            )}

                            {/* Delete User Button - Guarded */}
                            {hasPermission('Permission.Identity.Users.Delete') && !isUserAdmin && (
                              <Button 
                                variant="ghost" 
                                size="icon" 
                                onClick={() => requestConfirm('delete', usr)}
                                className="h-8 w-8 text-rose-500 hover:text-rose-900 hover:bg-rose-50 rounded-lg"
                                title="Delete User"
                              >
                                <Trash2 className="w-3.5 h-3.5" />
                              </Button>
                            )}

                            {!hasPermission('Permission.Identity.Users.Update') && 
                             !hasPermission('Permission.Identity.Users.Delete') && 
                             !hasPermission('Permission.Identity.Users.Lock') && 
                             !hasPermission('Permission.Identity.Users.Unlock') && (
                              <span className="text-xs text-neutral-400 font-medium italic">Read-Only</span>
                            )}
                          </div>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>

          {/* Table Pagination */}
          {!loading && totalPages > 1 && (
            <div className="flex items-center justify-between px-6 py-4 border-t border-neutral-100 bg-neutral-50/50">
              <div className="text-xs text-neutral-500">
                Page {pageNumber} of {totalPages}
              </div>
              <Pagination className="w-auto mx-0">
                <PaginationContent>
                  <PaginationItem>
                    <PaginationPrevious
                      href="#"
                      onClick={(e) => {
                        e.preventDefault();
                        if (pageNumber > 1) updateFilters({ page: String(pageNumber - 1) });
                      }}
                      className={pageNumber === 1 ? 'pointer-events-none opacity-50' : ''}
                    />
                  </PaginationItem>
                  
                  {(() => {
                    const pages: (number | 'ellipsis')[] = [];
                    pages.push(1);
                    if (pageNumber > 3) {
                      pages.push('ellipsis');
                    }
                    for (let i = Math.max(2, pageNumber - 1); i <= Math.min(totalPages - 1, pageNumber + 1); i++) {
                      if (!pages.includes(i)) {
                        pages.push(i);
                      }
                    }
                    if (pageNumber < totalPages - 2) {
                      pages.push('ellipsis');
                    }
                    if (totalPages > 1 && !pages.includes(totalPages)) {
                      pages.push(totalPages);
                    }
                    return pages;
                  })().map((page, idx) => (
                    <PaginationItem key={idx}>
                      {page === 'ellipsis' ? (
                        <PaginationEllipsis />
                      ) : (
                        <PaginationLink
                          href="#"
                          isActive={page === pageNumber}
                          onClick={(e) => {
                            e.preventDefault();
                            updateFilters({ page: String(page) });
                          }}
                        >
                          {page}
                        </PaginationLink>
                      )}
                    </PaginationItem>
                  ))}

                  <PaginationItem>
                    <PaginationNext
                      href="#"
                      onClick={(e) => {
                        e.preventDefault();
                        if (pageNumber < totalPages) updateFilters({ page: String(pageNumber + 1) });
                      }}
                      className={pageNumber === totalPages ? 'pointer-events-none opacity-50' : ''}
                    />
                  </PaginationItem>
                </PaginationContent>
              </Pagination>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Informative Security Panel */}
      <div className="p-4 bg-[#4285F4]/5 border border-[#4285F4]/10 rounded-2xl flex gap-3 text-[#4285F4] text-xs max-w-2xl leading-relaxed">
        <UserCheck className="w-5 h-5 shrink-0 mt-0.5" />
        <div className="space-y-1">
          <span className="font-bold block">Dynamic Action Authorization Guard Active</span>
          Admin panel buttons such as Create, Edit, Lock, and Unlock are controlled dynamically based on identity claim validation.
        </div>
      </div>

      {/* CREATE / EDIT SHEET PANEL */}
      <Sheet open={isFormSheetOpen} onOpenChange={setIsFormSheetOpen}>
        <SheetHeader>
          <SheetTitle>{formMode === 'create' ? 'Create New System Account' : 'Modify User details'}</SheetTitle>
          <SheetDescription>
            {formMode === 'create'
              ? 'Provide profile information and assign initial privileges.'
              : 'Edit name, phone number, and system access groups.'}
          </SheetDescription>
        </SheetHeader>

        <form onSubmit={handleSubmitUser} className="space-y-4 mt-4">
          
          {/* Full Name */}
          <div className="space-y-1">
            <label className="text-xs font-bold text-neutral-600 block">Full Name</label>
            <input
              type="text"
              value={formFullName}
              onChange={(e) => setFormFullName(e.target.value)}
              placeholder="e.g. Belal Badawy"
              className={`w-full p-2.5 border rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4285F4]/20 ${
                errors.fullName ? 'border-rose-500 focus:border-rose-500' : 'border-neutral-200 focus:border-[#4285F4]'
              }`}
            />
            {errors.fullName && <p className="text-rose-500 text-[11px] font-medium">{errors.fullName}</p>}
          </div>

          {/* Email (Creation Mode Only) */}
          <div className="space-y-1">
            <label className="text-xs font-bold text-neutral-600 block">Email Address</label>
            <input
              type="email"
              value={formEmail}
              disabled={formMode === 'edit'}
              onChange={(e) => setFormEmail(e.target.value)}
              placeholder="e.g. user@domain.com"
              className="w-full p-2.5 border border-neutral-200 rounded-xl text-sm disabled:bg-neutral-100 disabled:text-neutral-500 focus:outline-none focus:ring-2 focus:ring-[#4285F4]/20"
            />
            {errors.email && <p className="text-rose-500 text-[11px] font-medium">{errors.email}</p>}
          </div>

          {/* Phone Number */}
          <div className="space-y-1">
            <label className="text-xs font-bold text-neutral-600 block">Phone Number</label>
            <input
              type="text"
              value={formPhoneNumber}
              onChange={(e) => setFormPhoneNumber(e.target.value)}
              placeholder="e.g. +1 555-0199"
              className={`w-full p-2.5 border rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4285F4]/20 ${
                errors.phoneNumber ? 'border-rose-500 focus:border-rose-500' : 'border-neutral-200 focus:border-[#4285F4]'
              }`}
            />
            {errors.phoneNumber && <p className="text-rose-500 text-[11px] font-medium">{errors.phoneNumber}</p>}
          </div>

          {/* Password Fields (Creation Mode Only) */}
          {formMode === 'create' && (
            <>
              <div className="space-y-1">
                <label className="text-xs font-bold text-neutral-600 block">Password</label>
                <input
                  type="password"
                  value={formPassword}
                  onChange={(e) => setFormPassword(e.target.value)}
                  placeholder="Enter strong password"
                  className="w-full p-2.5 border border-neutral-200 rounded-xl text-sm focus:outline-none focus:ring-2"
                />
                <PasswordStrengthMeter password={formPassword} />
              </div>

              <div className="space-y-1">
                <label className="text-xs font-bold text-neutral-600 block">Confirm Password</label>
                <input
                  type="password"
                  value={formConfirmPassword}
                  onChange={(e) => setFormConfirmPassword(e.target.value)}
                  placeholder="Confirm password"
                  className={`w-full p-2.5 border rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#4285F4]/20 ${
                    errors.confirmPassword ? 'border-rose-500 focus:border-rose-500' : 'border-neutral-200 focus:border-[#4285F4]'
                  }`}
                />
                {errors.confirmPassword && <p className="text-rose-500 text-[11px] font-medium">{errors.confirmPassword}</p>}
              </div>

              {/* Status Toggles */}
              <div className="flex flex-col gap-2 p-3 bg-neutral-50 rounded-xl border border-neutral-100">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-neutral-700">Activate Account Instantly</span>
                  <input 
                    type="checkbox" 
                    checked={formActivateUser} 
                    onChange={(e) => setFormActivateUser(e.target.checked)}
                    className="w-4 h-4 accent-[#4285F4]"
                  />
                </div>
                <div className="flex items-center justify-between border-t border-neutral-200/50 pt-2 mt-1">
                  <span className="text-xs font-bold text-neutral-700">Auto Confirm Email</span>
                  <input 
                    type="checkbox" 
                    checked={formAutoConfirmEmail} 
                    onChange={(e) => setFormAutoConfirmEmail(e.target.checked)}
                    className="w-4 h-4 accent-[#4285F4]"
                  />
                </div>
              </div>
            </>
          )}

          {/* User Roles Selection */}
          <div className="space-y-2 border-t border-neutral-100 pt-4 mt-2">
            <span className="text-xs font-bold text-neutral-600 block">Assigned Roles / Access Groups</span>
            <div className="grid grid-cols-2 gap-2">
              {availableRoles.map((role) => (
                <div 
                  key={role.id} 
                  onClick={() => handleRoleToggle(role.name)}
                  className={`p-2.5 rounded-xl border flex items-center justify-between cursor-pointer select-none transition-all ${
                    formRoles.includes(role.name) 
                      ? 'border-[#4285F4] bg-[#4285F4]/5 text-neutral-900' 
                      : 'border-neutral-200 bg-white hover:bg-neutral-50 text-neutral-500'
                  }`}
                >
                  <div className="text-xs">
                    <span className="font-bold block">{role.name}</span>
                    <span className="text-[10px] text-neutral-400 font-medium block leading-tight">{role.description}</span>
                  </div>
                  <input 
                    type="checkbox" 
                    checked={formRoles.includes(role.name)}
                    readOnly
                    className="w-3.5 h-3.5 accent-[#4285F4]"
                  />
                </div>
              ))}
            </div>
          </div>

          <SheetFooter>
            <div className="flex w-full gap-2 mt-4">
              <Button 
                type="submit" 
                disabled={formSubmitting} 
                className="flex-1 bg-[#4285F4] hover:bg-[#3273DC] text-white"
              >
                {formSubmitting ? 'Saving changes...' : 'Save User'}
              </Button>
              <Button 
                type="button" 
                variant="outline" 
                onClick={() => setIsFormSheetOpen(false)}
                className="flex-1 rounded-xl"
              >
                Cancel
              </Button>
            </div>
          </SheetFooter>
        </form>
      </Sheet>

      {/* CONFIRMATION DIALOG */}
      <Dialog open={isConfirmDialogOpen} onOpenChange={setIsConfirmDialogOpen}>
        {targetUser && confirmAction && (
          <DialogContent>
            <DialogHeader>
              <DialogTitle className="capitalize">{confirmAction} Account</DialogTitle>
              <DialogDescription>
                {confirmAction === 'lock' && `Are you sure you want to lock the account of ${targetUser.fullName}? They will be blocked from logging into the application.`}
                {confirmAction === 'unlock' && `Are you sure you want to unlock the account of ${targetUser.fullName}?`}
                {confirmAction === 'activate' && `Are you sure you want to activate the account of ${targetUser.fullName}?`}
                {confirmAction === 'deactivate' && `Are you sure you want to deactivate the account of ${targetUser.fullName}? They will no longer be able to perform operations.`}
                {confirmAction === 'delete' && `Are you sure you want to delete ${targetUser.fullName}? This operation will delete their account data.`}
              </DialogDescription>
            </DialogHeader>
            <DialogFooter>
              <Button 
                variant={confirmAction === 'delete' ? 'destructive' : 'default'}
                onClick={executeConfirmAction}
                className="rounded-xl px-5"
              >
                Confirm
              </Button>
              <DialogClose onClick={() => setIsConfirmDialogOpen(false)}>
                Cancel
              </DialogClose>
            </DialogFooter>
          </DialogContent>
        )}
      </Dialog>
    </div>
  );
}
