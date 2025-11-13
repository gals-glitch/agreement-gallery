export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "13.0.4"
  }
  public: {
    Tables: {
      activity_log: {
        Row: {
          action: string
          description: string
          entity_id: string
          entity_type: string
          id: string
          new_values: Json | null
          old_values: Json | null
          performed_at: string
          performed_by: string | null
        }
        Insert: {
          action: string
          description: string
          entity_id: string
          entity_type: string
          id?: string
          new_values?: Json | null
          old_values?: Json | null
          performed_at?: string
          performed_by?: string | null
        }
        Update: {
          action?: string
          description?: string
          entity_id?: string
          entity_type?: string
          id?: string
          new_values?: Json | null
          old_values?: Json | null
          performed_at?: string
          performed_by?: string | null
        }
        Relationships: []
      }
      advanced_commission_calculations: {
        Row: {
          actor_id: string | null
          amount_before_cap: number | null
          applied_rate: number | null
          base_amount: number
          calculated_by: string | null
          calculation_basis:
            | Database["public"]["Enums"]["calculation_basis"]
            | null
          calculation_method: string | null
          calculation_run_id: string | null
          cap_remaining: number | null
          commission_type: string
          conditions_met: Json | null
          created_at: string | null
          distribution_id: string | null
          entity_name: string
          execution_time_ms: number | null
          finished_at: string | null
          gross_commission: number
          id: string
          input_ref: string | null
          net_commission: number
          notes: string | null
          rule_id: string | null
          rule_snapshot: Json
          rule_version: number | null
          started_at: string | null
          status: string | null
          tier_applied: number | null
          tier_applied_id: string | null
          vat_amount: number | null
          vat_rate: number | null
        }
        Insert: {
          actor_id?: string | null
          amount_before_cap?: number | null
          applied_rate?: number | null
          base_amount: number
          calculated_by?: string | null
          calculation_basis?:
            | Database["public"]["Enums"]["calculation_basis"]
            | null
          calculation_method?: string | null
          calculation_run_id?: string | null
          cap_remaining?: number | null
          commission_type: string
          conditions_met?: Json | null
          created_at?: string | null
          distribution_id?: string | null
          entity_name: string
          execution_time_ms?: number | null
          finished_at?: string | null
          gross_commission: number
          id?: string
          input_ref?: string | null
          net_commission: number
          notes?: string | null
          rule_id?: string | null
          rule_snapshot?: Json
          rule_version?: number | null
          started_at?: string | null
          status?: string | null
          tier_applied?: number | null
          tier_applied_id?: string | null
          vat_amount?: number | null
          vat_rate?: number | null
        }
        Update: {
          actor_id?: string | null
          amount_before_cap?: number | null
          applied_rate?: number | null
          base_amount?: number
          calculated_by?: string | null
          calculation_basis?:
            | Database["public"]["Enums"]["calculation_basis"]
            | null
          calculation_method?: string | null
          calculation_run_id?: string | null
          cap_remaining?: number | null
          commission_type?: string
          conditions_met?: Json | null
          created_at?: string | null
          distribution_id?: string | null
          entity_name?: string
          execution_time_ms?: number | null
          finished_at?: string | null
          gross_commission?: number
          id?: string
          input_ref?: string | null
          net_commission?: number
          notes?: string | null
          rule_id?: string | null
          rule_snapshot?: Json
          rule_version?: number | null
          started_at?: string | null
          status?: string | null
          tier_applied?: number | null
          tier_applied_id?: string | null
          vat_amount?: number | null
          vat_rate?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "advanced_commission_calculations_calculation_run_id_fkey"
            columns: ["calculation_run_id"]
            isOneToOne: false
            referencedRelation: "calculation_runs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "advanced_commission_calculations_distribution_id_fkey"
            columns: ["distribution_id"]
            isOneToOne: false
            referencedRelation: "investor_distributions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "advanced_commission_calculations_rule_id_fkey"
            columns: ["rule_id"]
            isOneToOne: false
            referencedRelation: "advanced_commission_rules"
            referencedColumns: ["id"]
          },
        ]
      }
      advanced_commission_rules: {
        Row: {
          archived_at: string | null
          base_rate: number | null
          calculation_basis:
            | Database["public"]["Enums"]["calculation_basis"]
            | null
          created_at: string | null
          created_by: string | null
          currency: string | null
          description: string | null
          effective_from: string | null
          effective_to: string | null
          entity_name: string | null
          entity_type: string
          fixed_amount: number | null
          fund_name: string | null
          id: string
          is_active: boolean | null
          lag_days: number | null
          max_amount: number | null
          min_amount: number | null
          name: string
          pdf_file_path: string | null
          priority: number | null
          requires_approval: boolean | null
          rule_checksum: string | null
          rule_type: Database["public"]["Enums"]["rule_type"]
          rule_version: number
          timing_mode: string | null
          updated_at: string | null
          vat_mode: string | null
          vat_rate_table: string | null
        }
        Insert: {
          archived_at?: string | null
          base_rate?: number | null
          calculation_basis?:
            | Database["public"]["Enums"]["calculation_basis"]
            | null
          created_at?: string | null
          created_by?: string | null
          currency?: string | null
          description?: string | null
          effective_from?: string | null
          effective_to?: string | null
          entity_name?: string | null
          entity_type: string
          fixed_amount?: number | null
          fund_name?: string | null
          id?: string
          is_active?: boolean | null
          lag_days?: number | null
          max_amount?: number | null
          min_amount?: number | null
          name: string
          pdf_file_path?: string | null
          priority?: number | null
          requires_approval?: boolean | null
          rule_checksum?: string | null
          rule_type?: Database["public"]["Enums"]["rule_type"]
          rule_version?: number
          timing_mode?: string | null
          updated_at?: string | null
          vat_mode?: string | null
          vat_rate_table?: string | null
        }
        Update: {
          archived_at?: string | null
          base_rate?: number | null
          calculation_basis?:
            | Database["public"]["Enums"]["calculation_basis"]
            | null
          created_at?: string | null
          created_by?: string | null
          currency?: string | null
          description?: string | null
          effective_from?: string | null
          effective_to?: string | null
          entity_name?: string | null
          entity_type?: string
          fixed_amount?: number | null
          fund_name?: string | null
          id?: string
          is_active?: boolean | null
          lag_days?: number | null
          max_amount?: number | null
          min_amount?: number | null
          name?: string
          pdf_file_path?: string | null
          priority?: number | null
          requires_approval?: boolean | null
          rule_checksum?: string | null
          rule_type?: Database["public"]["Enums"]["rule_type"]
          rule_version?: number
          timing_mode?: string | null
          updated_at?: string | null
          vat_mode?: string | null
          vat_rate_table?: string | null
        }
        Relationships: []
      }
      agreement_terms: {
        Row: {
          agreement_id: string
          created_at: string
          effective_from: string | null
          effective_to: string | null
          id: string
          is_active: boolean
          metadata: Json | null
          term_order: number
          term_type: string
          value_json: Json | null
          value_numeric: number | null
          value_text: string | null
        }
        Insert: {
          agreement_id: string
          created_at?: string
          effective_from?: string | null
          effective_to?: string | null
          id?: string
          is_active?: boolean
          metadata?: Json | null
          term_order?: number
          term_type: string
          value_json?: Json | null
          value_numeric?: number | null
          value_text?: string | null
        }
        Update: {
          agreement_id?: string
          created_at?: string
          effective_from?: string | null
          effective_to?: string | null
          id?: string
          is_active?: boolean
          metadata?: Json | null
          term_order?: number
          term_type?: string
          value_json?: Json | null
          value_numeric?: number | null
          value_text?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "agreement_terms_agreement_id_fkey"
            columns: ["agreement_id"]
            isOneToOne: false
            referencedRelation: "agreements"
            referencedColumns: ["id"]
          },
        ]
      }
      agreements: {
        Row: {
          agreement_type: string
          applies_scope: string
          created_at: string
          created_by: string | null
          deal_id: string | null
          deferred_offset_months: number | null
          deferred_rate_bps: number | null
          effective_from: string
          effective_to: string | null
          id: string
          inherit_fund_rates: boolean | null
          introduced_by_party_id: string
          metadata: Json | null
          name: string
          status: string
          track_key: string | null
          updated_at: string
          upfront_rate_bps: number | null
          vat_mode: string | null
        }
        Insert: {
          agreement_type: string
          applies_scope?: string
          created_at?: string
          created_by?: string | null
          deal_id?: string | null
          deferred_offset_months?: number | null
          deferred_rate_bps?: number | null
          effective_from: string
          effective_to?: string | null
          id?: string
          inherit_fund_rates?: boolean | null
          introduced_by_party_id: string
          metadata?: Json | null
          name: string
          status?: string
          track_key?: string | null
          updated_at?: string
          upfront_rate_bps?: number | null
          vat_mode?: string | null
        }
        Update: {
          agreement_type?: string
          applies_scope?: string
          created_at?: string
          created_by?: string | null
          deal_id?: string | null
          deferred_offset_months?: number | null
          deferred_rate_bps?: number | null
          effective_from?: string
          effective_to?: string | null
          id?: string
          inherit_fund_rates?: boolean | null
          introduced_by_party_id?: string
          metadata?: Json | null
          name?: string
          status?: string
          track_key?: string | null
          updated_at?: string
          upfront_rate_bps?: number | null
          vat_mode?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "agreements_deal_id_fkey"
            columns: ["deal_id"]
            isOneToOne: false
            referencedRelation: "deals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "agreements_introduced_by_party_id_fkey"
            columns: ["introduced_by_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
        ]
      }
      calc_run_checksums: {
        Row: {
          audit_checksum: string
          created_at: string | null
          detail_checksum: string
          inputs_checksum: string
          run_id: string
          summary_checksum: string
          vat_checksum: string
        }
        Insert: {
          audit_checksum: string
          created_at?: string | null
          detail_checksum: string
          inputs_checksum: string
          run_id: string
          summary_checksum: string
          vat_checksum: string
        }
        Update: {
          audit_checksum?: string
          created_at?: string | null
          detail_checksum?: string
          inputs_checksum?: string
          run_id?: string
          summary_checksum?: string
          vat_checksum?: string
        }
        Relationships: [
          {
            foreignKeyName: "calc_run_checksums_run_id_fkey"
            columns: ["run_id"]
            isOneToOne: true
            referencedRelation: "calculation_runs"
            referencedColumns: ["id"]
          },
        ]
      }
      calc_run_sources: {
        Row: {
          created_at: string | null
          run_id: string
          source_ids: string[]
          source_table: string
        }
        Insert: {
          created_at?: string | null
          run_id: string
          source_ids: string[]
          source_table: string
        }
        Update: {
          created_at?: string | null
          run_id?: string
          source_ids?: string[]
          source_table?: string
        }
        Relationships: [
          {
            foreignKeyName: "calc_run_sources_run_id_fkey"
            columns: ["run_id"]
            isOneToOne: false
            referencedRelation: "calculation_runs"
            referencedColumns: ["id"]
          },
        ]
      }
      calc_runs_rules: {
        Row: {
          created_at: string | null
          rule_id: string
          rule_snapshot: Json
          rule_version: number
          run_id: string
        }
        Insert: {
          created_at?: string | null
          rule_id: string
          rule_snapshot: Json
          rule_version?: number
          run_id: string
        }
        Update: {
          created_at?: string | null
          rule_id?: string
          rule_snapshot?: Json
          rule_version?: number
          run_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "calc_runs_rules_run_id_fkey"
            columns: ["run_id"]
            isOneToOne: false
            referencedRelation: "calculation_runs"
            referencedColumns: ["id"]
          },
        ]
      }
      calculation_runs: {
        Row: {
          completed_at: string | null
          created_at: string | null
          created_by: string | null
          error_message: string | null
          estimated_completion: string | null
          id: string
          is_incremental: boolean | null
          name: string
          period_end: string
          period_start: string
          progress_percentage: number | null
          run_type: string | null
          scope_filters: Json | null
          scope_type: string | null
          started_by: string | null
          status: string | null
          total_gross_fees: number | null
          total_net_payable: number | null
          total_vat: number | null
          updated_at: string | null
        }
        Insert: {
          completed_at?: string | null
          created_at?: string | null
          created_by?: string | null
          error_message?: string | null
          estimated_completion?: string | null
          id?: string
          is_incremental?: boolean | null
          name: string
          period_end: string
          period_start: string
          progress_percentage?: number | null
          run_type?: string | null
          scope_filters?: Json | null
          scope_type?: string | null
          started_by?: string | null
          status?: string | null
          total_gross_fees?: number | null
          total_net_payable?: number | null
          total_vat?: number | null
          updated_at?: string | null
        }
        Update: {
          completed_at?: string | null
          created_at?: string | null
          created_by?: string | null
          error_message?: string | null
          estimated_completion?: string | null
          id?: string
          is_incremental?: boolean | null
          name?: string
          period_end?: string
          period_start?: string
          progress_percentage?: number | null
          run_type?: string | null
          scope_filters?: Json | null
          scope_type?: string | null
          started_by?: string | null
          status?: string | null
          total_gross_fees?: number | null
          total_net_payable?: number | null
          total_vat?: number | null
          updated_at?: string | null
        }
        Relationships: []
      }
      calculation_step_traces: {
        Row: {
          calculation_id: string
          created_at: string | null
          id: string
          input_values: Json
          notes: string | null
          output_values: Json
          rule_version_id: string | null
          step_order: number
          step_type: string
        }
        Insert: {
          calculation_id: string
          created_at?: string | null
          id?: string
          input_values: Json
          notes?: string | null
          output_values: Json
          rule_version_id?: string | null
          step_order: number
          step_type: string
        }
        Update: {
          calculation_id?: string
          created_at?: string | null
          id?: string
          input_values?: Json
          notes?: string | null
          output_values?: Json
          rule_version_id?: string | null
          step_order?: number
          step_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "calculation_step_traces_calculation_id_fkey"
            columns: ["calculation_id"]
            isOneToOne: false
            referencedRelation: "advanced_commission_calculations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "calculation_step_traces_rule_version_id_fkey"
            columns: ["rule_version_id"]
            isOneToOne: false
            referencedRelation: "rule_versions"
            referencedColumns: ["id"]
          },
        ]
      }
      calculation_traces: {
        Row: {
          calculation_id: string
          calculation_result: Json
          created_at: string
          execution_order: number
          formula_used: string
          id: string
          input_data: Json
          rule_id: string | null
        }
        Insert: {
          calculation_id: string
          calculation_result: Json
          created_at?: string
          execution_order?: number
          formula_used: string
          id?: string
          input_data: Json
          rule_id?: string | null
        }
        Update: {
          calculation_id?: string
          calculation_result?: Json
          created_at?: string
          execution_order?: number
          formula_used?: string
          id?: string
          input_data?: Json
          rule_id?: string | null
        }
        Relationships: []
      }
      commission_tiers: {
        Row: {
          created_at: string | null
          description: string | null
          fixed_amount: number | null
          id: string
          max_threshold: number | null
          min_threshold: number
          rate: number
          rule_id: string | null
          tier_order: number
        }
        Insert: {
          created_at?: string | null
          description?: string | null
          fixed_amount?: number | null
          id?: string
          max_threshold?: number | null
          min_threshold: number
          rate: number
          rule_id?: string | null
          tier_order: number
        }
        Update: {
          created_at?: string | null
          description?: string | null
          fixed_amount?: number | null
          id?: string
          max_threshold?: number | null
          min_threshold?: number
          rate?: number
          rule_id?: string | null
          tier_order?: number
        }
        Relationships: [
          {
            foreignKeyName: "commission_tiers_rule_id_fkey"
            columns: ["rule_id"]
            isOneToOne: false
            referencedRelation: "advanced_commission_rules"
            referencedColumns: ["id"]
          },
        ]
      }
      credit_applications: {
        Row: {
          applied_amount: number
          applied_date: string
          calculation_run_id: string | null
          created_at: string
          credit_id: string
          distribution_id: string | null
          id: string
          notes: string | null
        }
        Insert: {
          applied_amount: number
          applied_date?: string
          calculation_run_id?: string | null
          created_at?: string
          credit_id: string
          distribution_id?: string | null
          id?: string
          notes?: string | null
        }
        Update: {
          applied_amount?: number
          applied_date?: string
          calculation_run_id?: string | null
          created_at?: string
          credit_id?: string
          distribution_id?: string | null
          id?: string
          notes?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "credit_applications_calculation_run_id_fkey"
            columns: ["calculation_run_id"]
            isOneToOne: false
            referencedRelation: "calculation_runs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "credit_applications_credit_id_fkey"
            columns: ["credit_id"]
            isOneToOne: false
            referencedRelation: "credits"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "credit_applications_distribution_id_fkey"
            columns: ["distribution_id"]
            isOneToOne: false
            referencedRelation: "investor_distributions"
            referencedColumns: ["id"]
          },
        ]
      }
      credits: {
        Row: {
          amount: number
          apply_policy: string | null
          created_at: string
          credit_type: string
          currency: string | null
          date_posted: string
          deal_id: string | null
          fund_name: string | null
          id: string
          investor_id: string
          investor_name: string
          notes: string | null
          remaining_balance: number
          scope: string
          status: string | null
          updated_at: string
        }
        Insert: {
          amount: number
          apply_policy?: string | null
          created_at?: string
          credit_type: string
          currency?: string | null
          date_posted: string
          deal_id?: string | null
          fund_name?: string | null
          id?: string
          investor_id: string
          investor_name: string
          notes?: string | null
          remaining_balance?: number
          scope?: string
          status?: string | null
          updated_at?: string
        }
        Update: {
          amount?: number
          apply_policy?: string | null
          created_at?: string
          credit_type?: string
          currency?: string | null
          date_posted?: string
          deal_id?: string | null
          fund_name?: string | null
          id?: string
          investor_id?: string
          investor_name?: string
          notes?: string | null
          remaining_balance?: number
          scope?: string
          status?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "credits_deal_id_fkey"
            columns: ["deal_id"]
            isOneToOne: false
            referencedRelation: "deals"
            referencedColumns: ["id"]
          },
        ]
      }
      deals: {
        Row: {
          close_date: string | null
          code: string
          created_at: string
          created_by: string | null
          fund_id: string
          id: string
          is_active: boolean
          metadata: Json | null
          name: string
          updated_at: string
        }
        Insert: {
          close_date?: string | null
          code: string
          created_at?: string
          created_by?: string | null
          fund_id: string
          id?: string
          is_active?: boolean
          metadata?: Json | null
          name: string
          updated_at?: string
        }
        Update: {
          close_date?: string | null
          code?: string
          created_at?: string
          created_by?: string | null
          fund_id?: string
          id?: string
          is_active?: boolean
          metadata?: Json | null
          name?: string
          updated_at?: string
        }
        Relationships: []
      }
      discounts: {
        Row: {
          amount: number
          created_at: string
          created_by: string | null
          discount_type: string
          effective_date: string
          expiry_date: string | null
          fund_name: string
          id: string
          investor_name: string
          is_refunded_via_distributions: boolean
          notes: string | null
          percentage: number | null
          status: string
          updated_at: string
        }
        Insert: {
          amount?: number
          created_at?: string
          created_by?: string | null
          discount_type: string
          effective_date: string
          expiry_date?: string | null
          fund_name: string
          id?: string
          investor_name: string
          is_refunded_via_distributions?: boolean
          notes?: string | null
          percentage?: number | null
          status?: string
          updated_at?: string
        }
        Update: {
          amount?: number
          created_at?: string
          created_by?: string | null
          discount_type?: string
          effective_date?: string
          expiry_date?: string | null
          fund_name?: string
          id?: string
          investor_name?: string
          is_refunded_via_distributions?: boolean
          notes?: string | null
          percentage?: number | null
          status?: string
          updated_at?: string
        }
        Relationships: []
      }
      distributor_rules: {
        Row: {
          created_at: string
          distributor_id: string
          id: string
          is_active: boolean
          priority: number
          rule_id: string
        }
        Insert: {
          created_at?: string
          distributor_id: string
          id?: string
          is_active?: boolean
          priority?: number
          rule_id: string
        }
        Update: {
          created_at?: string
          distributor_id?: string
          id?: string
          is_active?: boolean
          priority?: number
          rule_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_distributor_rules_rule_id"
            columns: ["rule_id"]
            isOneToOne: false
            referencedRelation: "advanced_commission_rules"
            referencedColumns: ["id"]
          },
        ]
      }
      entities: {
        Row: {
          address: string | null
          commission_rate: number | null
          country: string | null
          created_at: string
          created_by: string | null
          email: string | null
          entity_type: Database["public"]["Enums"]["entity_type"]
          id: string
          is_active: boolean
          name: string
          notes: string | null
          phone: string | null
          tax_id: string | null
          updated_at: string
        }
        Insert: {
          address?: string | null
          commission_rate?: number | null
          country?: string | null
          created_at?: string
          created_by?: string | null
          email?: string | null
          entity_type: Database["public"]["Enums"]["entity_type"]
          id?: string
          is_active?: boolean
          name: string
          notes?: string | null
          phone?: string | null
          tax_id?: string | null
          updated_at?: string
        }
        Update: {
          address?: string | null
          commission_rate?: number | null
          country?: string | null
          created_at?: string
          created_by?: string | null
          email?: string | null
          entity_type?: Database["public"]["Enums"]["entity_type"]
          id?: string
          is_active?: boolean
          name?: string
          notes?: string | null
          phone?: string | null
          tax_id?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      excel_import_jobs: {
        Row: {
          auto_run_calculation: boolean | null
          business_validation_errors: Json | null
          column_mapping: Json | null
          completed_at: string | null
          created_at: string
          duplicate_strategy: string | null
          error_count: number | null
          error_message: string | null
          file_name: string
          file_path: string
          id: string
          import_type: string | null
          mapping_template_id: string | null
          processed_rows: number | null
          progress_percentage: number | null
          started_at: string | null
          status: string
          success_count: number | null
          total_rows: number | null
          updated_at: string
          user_id: string
          validation_errors: Json | null
        }
        Insert: {
          auto_run_calculation?: boolean | null
          business_validation_errors?: Json | null
          column_mapping?: Json | null
          completed_at?: string | null
          created_at?: string
          duplicate_strategy?: string | null
          error_count?: number | null
          error_message?: string | null
          file_name: string
          file_path: string
          id?: string
          import_type?: string | null
          mapping_template_id?: string | null
          processed_rows?: number | null
          progress_percentage?: number | null
          started_at?: string | null
          status?: string
          success_count?: number | null
          total_rows?: number | null
          updated_at?: string
          user_id: string
          validation_errors?: Json | null
        }
        Update: {
          auto_run_calculation?: boolean | null
          business_validation_errors?: Json | null
          column_mapping?: Json | null
          completed_at?: string | null
          created_at?: string
          duplicate_strategy?: string | null
          error_count?: number | null
          error_message?: string | null
          file_name?: string
          file_path?: string
          id?: string
          import_type?: string | null
          mapping_template_id?: string | null
          processed_rows?: number | null
          progress_percentage?: number | null
          started_at?: string | null
          status?: string
          success_count?: number | null
          total_rows?: number | null
          updated_at?: string
          user_id?: string
          validation_errors?: Json | null
        }
        Relationships: []
      }
      export_jobs: {
        Row: {
          app_version: string | null
          checksum: string
          created_at: string | null
          created_by: string | null
          export_type: string
          file_name: string
          file_path: string | null
          id: string
          metadata: Json | null
          rounding_diff: number | null
          row_count: number | null
          run_id: string | null
        }
        Insert: {
          app_version?: string | null
          checksum: string
          created_at?: string | null
          created_by?: string | null
          export_type: string
          file_name: string
          file_path?: string | null
          id?: string
          metadata?: Json | null
          rounding_diff?: number | null
          row_count?: number | null
          run_id?: string | null
        }
        Update: {
          app_version?: string | null
          checksum?: string
          created_at?: string | null
          created_by?: string | null
          export_type?: string
          file_name?: string
          file_path?: string | null
          id?: string
          metadata?: Json | null
          rounding_diff?: number | null
          row_count?: number | null
          run_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "export_jobs_run_id_fkey"
            columns: ["run_id"]
            isOneToOne: false
            referencedRelation: "calculation_runs"
            referencedColumns: ["id"]
          },
        ]
      }
      export_templates: {
        Row: {
          column_definitions: Json
          created_at: string | null
          created_by: string | null
          filters_schema: Json | null
          id: string
          name: string
          template_type: string
          updated_at: string | null
        }
        Insert: {
          column_definitions: Json
          created_at?: string | null
          created_by?: string | null
          filters_schema?: Json | null
          id?: string
          name: string
          template_type: string
          updated_at?: string | null
        }
        Update: {
          column_definitions?: Json
          created_at?: string | null
          created_by?: string | null
          filters_schema?: Json | null
          id?: string
          name?: string
          template_type?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      fund_vi_tracks: {
        Row: {
          config_version: string
          created_at: string
          deferred_offset_months: number
          deferred_rate_bps: number
          id: string
          is_active: boolean
          max_raised: number | null
          min_raised: number
          track_key: string
          updated_at: string
          upfront_rate_bps: number
        }
        Insert: {
          config_version?: string
          created_at?: string
          deferred_offset_months?: number
          deferred_rate_bps: number
          id?: string
          is_active?: boolean
          max_raised?: number | null
          min_raised: number
          track_key: string
          updated_at?: string
          upfront_rate_bps: number
        }
        Update: {
          config_version?: string
          created_at?: string
          deferred_offset_months?: number
          deferred_rate_bps?: number
          id?: string
          is_active?: boolean
          max_raised?: number | null
          min_raised?: number
          track_key?: string
          updated_at?: string
          upfront_rate_bps?: number
        }
        Relationships: []
      }
      import_mapping_templates: {
        Row: {
          column_mappings: Json
          created_at: string | null
          created_by: string | null
          id: string
          import_type: string
          is_default: boolean | null
          name: string
          updated_at: string | null
        }
        Insert: {
          column_mappings: Json
          created_at?: string | null
          created_by?: string | null
          id?: string
          import_type: string
          is_default?: boolean | null
          name: string
          updated_at?: string | null
        }
        Update: {
          column_mappings?: Json
          created_at?: string | null
          created_by?: string | null
          id?: string
          import_type?: string
          is_default?: boolean | null
          name?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      import_staging: {
        Row: {
          created_at: string | null
          id: string
          import_job_id: string
          is_duplicate: boolean | null
          mapped_data: Json
          raw_data: Json
          row_number: number
          validation_errors: Json | null
          validation_status: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          import_job_id: string
          is_duplicate?: boolean | null
          mapped_data: Json
          raw_data: Json
          row_number: number
          validation_errors?: Json | null
          validation_status?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          import_job_id?: string
          is_duplicate?: boolean | null
          mapped_data?: Json
          raw_data?: Json
          row_number?: number
          validation_errors?: Json | null
          validation_status?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "import_staging_import_job_id_fkey"
            columns: ["import_job_id"]
            isOneToOne: false
            referencedRelation: "excel_import_jobs"
            referencedColumns: ["id"]
          },
        ]
      }
      investor_agreement_links: {
        Row: {
          agreement_id: string
          created_at: string
          created_by: string | null
          id: string
          introduced_by_party_id: string
          investor_id: string
          is_active: boolean
          link_effective_from: string
          link_effective_to: string | null
          metadata: Json | null
        }
        Insert: {
          agreement_id: string
          created_at?: string
          created_by?: string | null
          id?: string
          introduced_by_party_id: string
          investor_id: string
          is_active?: boolean
          link_effective_from?: string
          link_effective_to?: string | null
          metadata?: Json | null
        }
        Update: {
          agreement_id?: string
          created_at?: string
          created_by?: string | null
          id?: string
          introduced_by_party_id?: string
          investor_id?: string
          is_active?: boolean
          link_effective_from?: string
          link_effective_to?: string | null
          metadata?: Json | null
        }
        Relationships: [
          {
            foreignKeyName: "investor_agreement_links_agreement_id_fkey"
            columns: ["agreement_id"]
            isOneToOne: false
            referencedRelation: "agreements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "investor_agreement_links_introduced_by_party_id_fkey"
            columns: ["introduced_by_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "investor_agreement_links_investor_id_fkey"
            columns: ["investor_id"]
            isOneToOne: false
            referencedRelation: "investors"
            referencedColumns: ["id"]
          },
        ]
      }
      investor_distributions: {
        Row: {
          calculation_run_id: string | null
          created_at: string | null
          deal_id: string | null
          distribution_amount: number
          distribution_date: string | null
          distributor_name: string | null
          fund_name: string | null
          id: string
          import_job_id: string | null
          investor_id: string | null
          investor_name: string
          partner_name: string | null
          referrer_name: string | null
        }
        Insert: {
          calculation_run_id?: string | null
          created_at?: string | null
          deal_id?: string | null
          distribution_amount: number
          distribution_date?: string | null
          distributor_name?: string | null
          fund_name?: string | null
          id?: string
          import_job_id?: string | null
          investor_id?: string | null
          investor_name: string
          partner_name?: string | null
          referrer_name?: string | null
        }
        Update: {
          calculation_run_id?: string | null
          created_at?: string | null
          deal_id?: string | null
          distribution_amount?: number
          distribution_date?: string | null
          distributor_name?: string | null
          fund_name?: string | null
          id?: string
          import_job_id?: string | null
          investor_id?: string | null
          investor_name?: string
          partner_name?: string | null
          referrer_name?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "investor_distributions_calculation_run_id_fkey"
            columns: ["calculation_run_id"]
            isOneToOne: false
            referencedRelation: "calculation_runs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "investor_distributions_deal_id_fkey"
            columns: ["deal_id"]
            isOneToOne: false
            referencedRelation: "deals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "investor_distributions_import_job_id_fkey"
            columns: ["import_job_id"]
            isOneToOne: false
            referencedRelation: "excel_import_jobs"
            referencedColumns: ["id"]
          },
        ]
      }
      investors: {
        Row: {
          address: string | null
          country: string | null
          created_at: string
          created_by: string | null
          email: string | null
          id: string
          investment_capacity: number | null
          investor_type: string | null
          is_active: boolean
          kyc_status: string | null
          name: string
          notes: string | null
          party_entity_id: string
          phone: string | null
          risk_profile: string | null
          tax_id: string | null
          updated_at: string
        }
        Insert: {
          address?: string | null
          country?: string | null
          created_at?: string
          created_by?: string | null
          email?: string | null
          id?: string
          investment_capacity?: number | null
          investor_type?: string | null
          is_active?: boolean
          kyc_status?: string | null
          name: string
          notes?: string | null
          party_entity_id: string
          phone?: string | null
          risk_profile?: string | null
          tax_id?: string | null
          updated_at?: string
        }
        Update: {
          address?: string | null
          country?: string | null
          created_at?: string
          created_by?: string | null
          email?: string | null
          id?: string
          investment_capacity?: number | null
          investor_type?: string | null
          is_active?: boolean
          kyc_status?: string | null
          name?: string
          notes?: string | null
          party_entity_id?: string
          phone?: string | null
          risk_profile?: string | null
          tax_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_investors_party_entity"
            columns: ["party_entity_id"]
            isOneToOne: false
            referencedRelation: "entities"
            referencedColumns: ["id"]
          },
        ]
      }
      notification_emails: {
        Row: {
          created_at: string
          email: string
          entity_id: string
          entity_type: string
          id: string
          is_primary: boolean
        }
        Insert: {
          created_at?: string
          email: string
          entity_id: string
          entity_type: string
          id?: string
          is_primary?: boolean
        }
        Update: {
          created_at?: string
          email?: string
          entity_id?: string
          entity_type?: string
          id?: string
          is_primary?: boolean
        }
        Relationships: []
      }
      parties: {
        Row: {
          address: string | null
          country: string | null
          created_at: string
          created_by: string | null
          email: string | null
          id: string
          is_active: boolean
          metadata: Json | null
          name: string
          party_type: string
          phone: string | null
          tax_id: string | null
          updated_at: string
        }
        Insert: {
          address?: string | null
          country?: string | null
          created_at?: string
          created_by?: string | null
          email?: string | null
          id?: string
          is_active?: boolean
          metadata?: Json | null
          name: string
          party_type: string
          phone?: string | null
          tax_id?: string | null
          updated_at?: string
        }
        Update: {
          address?: string | null
          country?: string | null
          created_at?: string
          created_by?: string | null
          email?: string | null
          id?: string
          is_active?: boolean
          metadata?: Json | null
          name?: string
          party_type?: string
          phone?: string | null
          tax_id?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      profiles: {
        Row: {
          avatar_url: string | null
          created_at: string
          display_name: string | null
          email: string | null
          first_name: string | null
          id: string
          last_name: string | null
          updated_at: string
        }
        Insert: {
          avatar_url?: string | null
          created_at?: string
          display_name?: string | null
          email?: string | null
          first_name?: string | null
          id: string
          last_name?: string | null
          updated_at?: string
        }
        Update: {
          avatar_url?: string | null
          created_at?: string
          display_name?: string | null
          email?: string | null
          first_name?: string | null
          id?: string
          last_name?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      rule_conditions: {
        Row: {
          condition_group: number | null
          created_at: string | null
          field_name: string
          id: string
          is_required: boolean | null
          operator: Database["public"]["Enums"]["condition_operator"]
          rule_id: string | null
          value_array: string[] | null
          value_date: string | null
          value_number: number | null
          value_text: string | null
        }
        Insert: {
          condition_group?: number | null
          created_at?: string | null
          field_name: string
          id?: string
          is_required?: boolean | null
          operator: Database["public"]["Enums"]["condition_operator"]
          rule_id?: string | null
          value_array?: string[] | null
          value_date?: string | null
          value_number?: number | null
          value_text?: string | null
        }
        Update: {
          condition_group?: number | null
          created_at?: string | null
          field_name?: string
          id?: string
          is_required?: boolean | null
          operator?: Database["public"]["Enums"]["condition_operator"]
          rule_id?: string | null
          value_array?: string[] | null
          value_date?: string | null
          value_number?: number | null
          value_text?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "rule_conditions_rule_id_fkey"
            columns: ["rule_id"]
            isOneToOne: false
            referencedRelation: "advanced_commission_rules"
            referencedColumns: ["id"]
          },
        ]
      }
      rule_execution_history: {
        Row: {
          calculation_run_id: string | null
          conditions_evaluated: Json | null
          created_at: string | null
          distribution_id: string | null
          error_message: string | null
          execution_result: string | null
          execution_time_ms: number | null
          id: string
          rule_id: string | null
        }
        Insert: {
          calculation_run_id?: string | null
          conditions_evaluated?: Json | null
          created_at?: string | null
          distribution_id?: string | null
          error_message?: string | null
          execution_result?: string | null
          execution_time_ms?: number | null
          id?: string
          rule_id?: string | null
        }
        Update: {
          calculation_run_id?: string | null
          conditions_evaluated?: Json | null
          created_at?: string | null
          distribution_id?: string | null
          error_message?: string | null
          execution_result?: string | null
          execution_time_ms?: number | null
          id?: string
          rule_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "rule_execution_history_calculation_run_id_fkey"
            columns: ["calculation_run_id"]
            isOneToOne: false
            referencedRelation: "calculation_runs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "rule_execution_history_distribution_id_fkey"
            columns: ["distribution_id"]
            isOneToOne: false
            referencedRelation: "investor_distributions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "rule_execution_history_rule_id_fkey"
            columns: ["rule_id"]
            isOneToOne: false
            referencedRelation: "advanced_commission_rules"
            referencedColumns: ["id"]
          },
        ]
      }
      rule_versions: {
        Row: {
          checksum: string
          created_at: string | null
          created_by: string | null
          effective_from: string
          effective_to: string | null
          id: string
          rule_id: string
          rule_snapshot: Json
          version_number: string
        }
        Insert: {
          checksum: string
          created_at?: string | null
          created_by?: string | null
          effective_from: string
          effective_to?: string | null
          id?: string
          rule_id: string
          rule_snapshot: Json
          version_number: string
        }
        Update: {
          checksum?: string
          created_at?: string | null
          created_by?: string | null
          effective_from?: string
          effective_to?: string | null
          id?: string
          rule_id?: string
          rule_snapshot?: Json
          version_number?: string
        }
        Relationships: [
          {
            foreignKeyName: "rule_versions_rule_id_fkey"
            columns: ["rule_id"]
            isOneToOne: false
            referencedRelation: "advanced_commission_rules"
            referencedColumns: ["id"]
          },
        ]
      }
      run_records: {
        Row: {
          calculation_run_id: string | null
          config_version: string
          created_at: string
          created_by: string | null
          id: string
          inputs: Json
          outputs: Json
          run_hash: string | null
          scope_breakdown: Json | null
        }
        Insert: {
          calculation_run_id?: string | null
          config_version: string
          created_at?: string
          created_by?: string | null
          id?: string
          inputs: Json
          outputs: Json
          run_hash?: string | null
          scope_breakdown?: Json | null
        }
        Update: {
          calculation_run_id?: string | null
          config_version?: string
          created_at?: string
          created_by?: string | null
          id?: string
          inputs?: Json
          outputs?: Json
          run_hash?: string | null
          scope_breakdown?: Json | null
        }
        Relationships: [
          {
            foreignKeyName: "run_records_calculation_run_id_fkey"
            columns: ["calculation_run_id"]
            isOneToOne: false
            referencedRelation: "calculation_runs"
            referencedColumns: ["id"]
          },
        ]
      }
      sub_agents: {
        Row: {
          created_at: string
          distributor_id: string
          email: string
          id: string
          is_active: boolean
          name: string
          split_percentage: number
          updated_at: string
        }
        Insert: {
          created_at?: string
          distributor_id: string
          email: string
          id?: string
          is_active?: boolean
          name: string
          split_percentage: number
          updated_at?: string
        }
        Update: {
          created_at?: string
          distributor_id?: string
          email?: string
          id?: string
          is_active?: boolean
          name?: string
          split_percentage?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_sub_agents_distributor_id"
            columns: ["distributor_id"]
            isOneToOne: false
            referencedRelation: "entities"
            referencedColumns: ["id"]
          },
        ]
      }
      user_roles: {
        Row: {
          created_at: string | null
          id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          created_at?: string | null
          id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: []
      }
      vat_rates: {
        Row: {
          country_code: string
          created_at: string | null
          created_by: string | null
          effective_from: string
          effective_to: string | null
          id: string
          is_default: boolean | null
          rate: number
        }
        Insert: {
          country_code: string
          created_at?: string | null
          created_by?: string | null
          effective_from: string
          effective_to?: string | null
          id?: string
          is_default?: boolean | null
          rate: number
        }
        Update: {
          country_code?: string
          created_at?: string | null
          created_by?: string | null
          effective_from?: string
          effective_to?: string | null
          id?: string
          is_default?: boolean | null
          rate?: number
        }
        Relationships: []
      }
      workflow_approvals: {
        Row: {
          approval_type: string
          approved_at: string | null
          approved_by: string | null
          entity_data: Json | null
          entity_id: string
          entity_type: string
          first_approver: string | null
          id: string
          rejection_reason: string | null
          requested_at: string
          requested_by: string | null
          requires_two_person_approval: boolean
          second_approver: string | null
          status: string
        }
        Insert: {
          approval_type: string
          approved_at?: string | null
          approved_by?: string | null
          entity_data?: Json | null
          entity_id: string
          entity_type: string
          first_approver?: string | null
          id?: string
          rejection_reason?: string | null
          requested_at?: string
          requested_by?: string | null
          requires_two_person_approval?: boolean
          second_approver?: string | null
          status?: string
        }
        Update: {
          approval_type?: string
          approved_at?: string | null
          approved_by?: string | null
          entity_data?: Json | null
          entity_id?: string
          entity_type?: string
          first_approver?: string | null
          id?: string
          rejection_reason?: string | null
          requested_at?: string
          requested_by?: string | null
          requires_two_person_approval?: boolean
          second_approver?: string | null
          status?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      generate_rule_checksum: {
        Args: { rule_data: Json }
        Returns: string
      }
      get_vat_rate: {
        Args: { calculation_date: string; country: string }
        Returns: number
      }
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      is_admin_or_manager: {
        Args: { _user_id: string }
        Returns: boolean
      }
    }
    Enums: {
      app_role: "admin" | "manager" | "user"
      calculation_basis:
        | "distribution_amount"
        | "cumulative_amount"
        | "monthly_volume"
        | "quarterly_volume"
        | "annual_volume"
      condition_operator:
        | "equals"
        | "greater_than"
        | "less_than"
        | "greater_equal"
        | "less_equal"
        | "between"
        | "in"
        | "not_in"
      entity_type: "distributor" | "referrer" | "partner"
      rule_type:
        | "percentage"
        | "fixed_amount"
        | "tiered"
        | "hybrid"
        | "conditional"
        | "management_fee"
        | "promote_share"
        | "credit_netting"
        | "discount"
        | "sub_agent_split"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: ["admin", "manager", "user"],
      calculation_basis: [
        "distribution_amount",
        "cumulative_amount",
        "monthly_volume",
        "quarterly_volume",
        "annual_volume",
      ],
      condition_operator: [
        "equals",
        "greater_than",
        "less_than",
        "greater_equal",
        "less_equal",
        "between",
        "in",
        "not_in",
      ],
      entity_type: ["distributor", "referrer", "partner"],
      rule_type: [
        "percentage",
        "fixed_amount",
        "tiered",
        "hybrid",
        "conditional",
        "management_fee",
        "promote_share",
        "credit_netting",
        "discount",
        "sub_agent_split",
      ],
    },
  },
} as const
