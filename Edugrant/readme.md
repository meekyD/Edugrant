# Scholarship Grant Distribution Smart Contract

## Overview
A Clarity smart contract for managing and distributing scholarship grants to students. This contract enables a foundation administrator to approve applicants, set scholarship amounts, and control the disbursement of funds.

## Features
- **Applicant Management**: Approve or revoke student applications
- **Credential Verification**: Track academic qualifications
- **Scholarship Allocation**: Set individual scholarship amounts
- **Grant Disbursement**: Students can claim their approved scholarships
- **Bulk Operations**: Distribute scholarships to multiple students simultaneously
- **Admin Controls**: Toggle grant distribution on/off

## Constants
- `foundation-admin`: The contract deployer who has administrative privileges
- **Error Codes**:
  - `err-admin-only (u100)`: Operation requires admin privileges
  - `err-grant-received (u101)`: Scholarship already disbursed
  - `err-not-approved (u102)`: Student not approved
  - `err-no-scholarship (u103)`: No scholarship amount set
  - `err-grants-paused (u104)`: Grant distribution is paused
  - `err-invalid-applicant (u105)`: Invalid applicant principal
  - `err-invalid-grant-amount (u106)`: Invalid grant amount

## Data Structures

### Data Variables
- `total-scholarship-fund`: Total available funds (initial: 5,000,000)
- `grants-enabled`: Toggle for enabling/disabling disbursements

### Data Maps
- `scholarship-amounts`: Maps student principals to their scholarship amounts
- `grant-disbursed`: Tracks whether a student has received their grant
- `academic-credentials`: Stores academic qualification status
- `approved-applicants`: Tracks pre-approved students

## Public Functions

### Admin Functions

#### `approve-applicant`
```clarity
(approve-applicant (student principal))
```
Approves a student to receive scholarship grants.
- **Access**: Admin only
- **Parameters**: Student principal address
- **Returns**: `(ok true)` on success

#### `revoke-approval`
```clarity
(revoke-approval (student principal))
```
Revokes a student's approval status.
- **Access**: Admin only
- **Parameters**: Student principal address
- **Returns**: `(ok true)` on success

#### `set-credentials`
```clarity
(set-credentials (student principal) (qualified bool))
```
Sets or updates a student's academic credentials.
- **Access**: Admin only
- **Parameters**: 
  - `student`: Student principal address
  - `qualified`: Boolean indicating qualification status
- **Returns**: `(ok true)` on success

#### `set-scholarship-amount`
```clarity
(set-scholarship-amount (student principal) (amount uint))
```
Assigns a scholarship amount to a student.
- **Access**: Admin only
- **Parameters**:
  - `student`: Student principal address
  - `amount`: Scholarship amount (must be > 0 and ≤ total fund)
- **Returns**: `(ok true)` on success

#### `bulk-disburse`
```clarity
(bulk-disburse (students (list 200 principal)) (amounts (list 200 uint)))
```
Distributes scholarships to multiple students at once.
- **Access**: Admin only
- **Parameters**:
  - `students`: List of student principals (max 200)
  - `amounts`: Corresponding scholarship amounts
- **Returns**: `(ok true)` on success
- **Note**: Lists must be equal length

#### `toggle-grants`
```clarity
(toggle-grants)
```
Enables or disables grant disbursement.
- **Access**: Admin only
- **Returns**: `(ok true)` with updated status

### Student Functions

#### `receive-scholarship`
```clarity
(receive-scholarship)
```
Allows an approved student to claim their scholarship.
- **Access**: Public (students only)
- **Requirements**:
  - Grants must be enabled
  - Student must be approved
  - Student must have credentials
  - Scholarship must be assigned
  - Grant not already disbursed
- **Returns**: `(ok amount)` with scholarship amount

## Read-Only Functions

#### `get-scholarship-amount`
```clarity
(get-scholarship-amount (student principal))
```
Returns the scholarship amount for a student (0 if not set).

#### `is-grant-disbursed`
```clarity
(is-grant-disbursed (student principal))
```
Checks if a student has received their grant.

#### `check-approval-status`
```clarity
(check-approval-status (student principal))
```
Verifies if a student is approved and has credentials.

#### `are-grants-enabled`
```clarity
(are-grants-enabled)
```
Returns the current status of grant disbursement.

#### `get-total-fund`
```clarity
(get-total-fund)
```
Returns the total scholarship fund amount.

#### `get-student-info`
```clarity
(get-student-info (student principal))
```
Returns comprehensive information about a student:
- `scholarship`: Assigned scholarship amount
- `disbursed`: Whether grant has been received
- `approved`: Full approval status
- `is-approved-applicant`: Applicant approval status
- `has-credentials`: Credential verification status
- `can-receive`: Whether student can currently claim scholarship

## Usage Workflow

### For Administrators
1. Deploy the contract (deployer becomes admin)
2. Approve applicants using `approve-applicant`
3. Set academic credentials with `set-credentials`
4. Assign scholarship amounts via `set-scholarship-amount`
5. Enable grants with `toggle-grants`
6. Optionally use `bulk-disburse` for multiple students

### For Students
1. Wait for admin approval and credential verification
2. Check eligibility using `get-student-info`
3. Call `receive-scholarship` when grants are enabled
4. Receive scholarship amount

## Security Considerations
- Only the contract deployer has admin privileges
- Students cannot approve themselves or modify scholarship amounts
- Double disbursement is prevented
- Applicant validation prevents invalid principals
- Scholarship amounts are capped by total fund
