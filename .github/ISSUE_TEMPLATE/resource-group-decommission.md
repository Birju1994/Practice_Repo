---
name: Resource Group Decommission
about: Request to decommission an Azure Resource Group.
title: ''
labels: ''
assignees: ''

---

name: Resource Group Decommission
description: Request to decommission and delete an Azure Resource Group
title: "[Decommission] "
labels:
  - resource-group
  - decommission

body:

  - type: markdown
    attributes:
      value: |
        ## Azure Resource Group Decommission Request

        Please provide all required information before submitting this request.
        **Warning:** Decommissioning a Resource Group may permanently delete
        the resources contained within it.

  - type: input
    id: resource-group-name
    attributes:
      label: Resource Group Name
      description: Enter the Azure Resource Group name to be decommissioned.
      placeholder: "rg-example-dev"
    validations:
      required: true

  - type: input
    id: subscription-id
    attributes:
      label: Azure Subscription ID
      description: Enter the Azure Subscription ID containing the Resource Group.
      placeholder: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    validations:
      required: true

  - type: dropdown
    id: environment
    attributes:
      label: Environment
      description: Select the environment associated with the Resource Group.
      options:
        - Development
        - Test
        - QA
        - UAT
        - Production
    validations:
      required: true

  - type: textarea
    id: reason
    attributes:
      label: Decommission Reason
      description: Explain why the Resource Group needs to be decommissioned.
      placeholder: |
        Example:
        Environment is no longer required after project completion.
    validations:
      required: true

  - type: textarea
    id: resources
    attributes:
      label: Resources to be Decommissioned
      description: List the important Azure resources contained in the Resource Group.
      placeholder: |
        Example:
        - App Service
        - Storage Account
        - Key Vault
        - Azure SQL Database
    validations:
      required: true

  - type: textarea
    id: backup
    attributes:
      label: Backup / Data Retention Confirmation
      description: Confirm that required data has been backed up or is no longer required.
      placeholder: |
        Example:
        Required database backup completed.
        No additional data retention is required.
    validations:
      required: true

  - type: dropdown
    id: approval
    attributes:
      label: Approval Status
      description: Confirm that the required approval has been obtained.
      options:
        - Pending Approval
        - Approved
    validations:
      required: true

  - type: input
    id: approver
    attributes:
      label: Approver
      description: Enter the GitHub username or name of the person who approved the decommission.
      placeholder: "@username"
    validations:
      required: true

  - type: textarea
    id: additional-information
    attributes:
      label: Additional Information
      description: Add any additional information, dependencies, or considerations.
      placeholder: "Add relevant details here..."

  - type: checkboxes
    id: confirmation
    attributes:
      label: Decommission Confirmation
      options:
        - label: I confirm that the Resource Group and its resources can be permanently deleted.
          required: true
        - label: I confirm that required backups and data retention requirements have been addressed.
          required: true
        - label: I confirm that the required approval has been obtained.
          required: true
