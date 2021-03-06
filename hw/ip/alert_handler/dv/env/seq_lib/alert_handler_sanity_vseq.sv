// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// basic sanity test vseq
class alert_handler_sanity_vseq extends alert_handler_base_vseq;
  `uvm_object_utils(alert_handler_sanity_vseq)

  `uvm_object_new

  rand bit [NUM_ALERT_HANDLER_CLASSES-1:0] intr_en;
  rand bit [alert_pkg::NAlerts-1:0]        alert_trigger;
  rand bit [alert_pkg::NAlerts-1:0]        alert_en;
  rand bit [alert_pkg::NAlerts*2-1:0]      alert_class_map;
  rand int max_phase_cyc;
  rand bit do_clr_esc;
  rand bit do_wr_phases_cyc;
  int      max_wait_phases_cyc = MIN_CYCLE_PER_PHASE * NUM_ESC_PHASES;

  constraint wr_phases_cyc_c {
    do_wr_phases_cyc == 0;
    max_phase_cyc == 2; // default each phases consume 1 cycle, but esc signal will have 2 cycs
  }

  constraint enable_one_alert_c {
    $onehot(alert_en);
  }

  constraint max_phase_cyc_c {
    max_phase_cyc inside {[0:1_000]};
  }

  constraint enable_classa_only_c {
    alert_class_map == 0; // all the alerts assign to classa
  }

  task body();
    run_esc_rsp_seq_nonblocking();
    for (int i = 1; i <= num_trans; i++) begin
      bit [NUM_ALERT_HANDLER_CLASSES-1:0] intr_trigger;
      bit [TL_DW-1:0] intr_state_exp_val;
      `DV_CHECK_RANDOMIZE_FATAL(this)

      `uvm_info(`gfn,
          $sformatf("starting seq %0d/%0d: intr_en=%0b, alert=%0b, alert_en=%0b, alert_class=%0b",
          i, num_trans, intr_en, alert_trigger, alert_en, alert_class_map), UVM_LOW)
      alert_handler_init(.intr_en(intr_en), .alert_en(alert_en), .alert_class(alert_class_map));

      alert_handle_rand_wr_class_ctrl();

      if (do_wr_phases_cyc) begin
        wr_phases_cycle(max_phase_cyc);
        max_wait_phases_cyc = (max_wait_phases_cyc > (max_phase_cyc * NUM_ESC_PHASES)) ?
                               max_wait_phases_cyc : (max_phase_cyc * NUM_ESC_PHASES);
      end

      drive_alert(alert_trigger);

      // read and check interrupt
      if (alert_en & alert_trigger) begin
        // calculate which interrupt should be triggered
        for (int i = 0; i < alert_pkg::NAlerts; i++) begin
          if (alert_en[i] && alert_trigger[i]) begin
            intr_trigger[((alert_class_map >> i*2) & 2'b11)] = 1;
          end
        end
        if ((intr_en & intr_trigger) > '0) begin
          wait(cfg.intr_vif.pins[(NUM_ALERT_HANDLER_CLASSES-1):0] == (intr_trigger & intr_en));
          check_interrupts(.interrupts(intr_trigger & intr_en), .check_set(1));
        end
        if ((~intr_en & intr_trigger) > '0) begin
          csr_spinwait(.ptr(ral.intr_state), .exp_data(~intr_en & intr_trigger));
          csr_wr(.csr(ral.intr_state), .value(~intr_en & intr_trigger));
        end
      end

      // wait to ensure all escalation phases are done before clearing the esc class
      wait_alert_esc_handshake_done(max_wait_phases_cyc);
      read_alert_cause();
      if (do_clr_esc) clear_esc();
    end
  endtask : body

endclass : alert_handler_sanity_vseq
