///|
fn extra_rules() -> String {
  (
    #|.mmui-overlay{background:rgba(0,0,0,.4)}
    #|.mmui-surface{box-sizing:border-box;overflow:auto;padding:16px;border:1px solid var(--mmui-border);border-radius:var(--mmui-radius);background:var(--mmui-background);color:var(--mmui-foreground);box-shadow:0 8px 24px rgba(0,0,0,.16)}
    #|.mmui-surface-title{font-size:18px;font-weight:600;margin-bottom:12px}
    #|.mmui-surface-description{font-size:14px;color:var(--mmui-muted-foreground)}
    #|.mmui-surface-header{display:flex;flex-direction:column;gap:8px;padding-bottom:12px}
    #|.mmui-surface-footer{display:flex;align-items:center;justify-content:flex-end;gap:8px;padding-top:12px}
    #|.mmui-surface-arrow{box-sizing:border-box;border:1px solid var(--mmui-border)}
    #|.mmui-menu,.mmui-menu-submenu{display:flex;flex-direction:column;gap:4px}
    #|.mmui-menu-item{text-align:left;background:transparent;color:var(--mmui-foreground);border:0}
    #|.mmui-menu-separator{height:1px;background:var(--mmui-border);margin:4px 0}
    #|.mmui-menu-group{display:flex;flex-direction:column;gap:4px}
    #|.mmui-menu-shortcut{font-size:12px;color:var(--mmui-muted-foreground);margin-left:auto}
    #|.mmui-menu-indicator{display:inline-flex;align-items:center;justify-content:center;width:16px;min-height:16px;flex-shrink:0}
    #|.mmui-menu-chevron{margin-left:auto;color:var(--mmui-muted-foreground)}
    #|.mmui-rtl .mmui-menu-chevron{margin-left:0;margin-right:auto;transform:rotate(180deg)}
    #|.mmui-menubar,.mmui-tab-list,.mmui-calendar-header,.mmui-pagination{display:flex;align-items:center;gap:8px}
    #|.mmui-calendar-day{box-sizing:border-box;margin:0;padding:0;border:0;border-radius:4px;font-size:14px;background:transparent;color:var(--mmui-foreground)}
    #|.mmui-selected{background:var(--mmui-primary);color:var(--mmui-primary-foreground)}
    #|.mmui-table{min-width:100%;display:flex;flex-direction:column}
    #|.mmui-table-row{display:flex;align-items:center;border-bottom:1px solid var(--mmui-border)}
    #|.mmui-table-cell,.mmui-table-head{flex:1;min-width:96px;padding:8px;box-sizing:border-box}
    #|.mmui-toaster{position:fixed;left:12px;right:12px;bottom:24px;display:flex;flex-direction:column;gap:8px}
    #|.mmui-toast{border:1px solid var(--mmui-border);border-radius:var(--mmui-radius);padding:12px;background:var(--mmui-background);color:var(--mmui-foreground);box-shadow:0 4px 16px rgba(0,0,0,.12)}
    #|.mmui-resize-handle{background:var(--mmui-border);min-width:12px;min-height:12px}
    #|.mmui-navigation-menu,.mmui-message-scroller{display:flex;flex-direction:column;gap:8px}
    #|.mmui-accordion-item{border-bottom:1px solid var(--mmui-border)}
    #|.mmui-overlay-trigger,.mmui-drawer-root,.mmui-form-control,.mmui-select-group{min-width:0;box-sizing:border-box}
    #|.mmui-badge-link,.mmui-breadcrumb-link,.mmui-item-link,.mmui-marker-link,.mmui-bubble-content-link{color:inherit;text-decoration:none}
    #|.mmui-breadcrumb-ellipsis{padding:0 4px;color:var(--mmui-muted-foreground)}
    #|.mmui-bubble-content-button,.mmui-input-group-button{margin:0;border:0;background:transparent;color:inherit;font-size:inherit}
    #|.mmui-calendar-grid{display:flex;flex-wrap:wrap;width:100%}
    #|.mmui-calendar-weekdays{display:flex;padding:8px 0;color:var(--mmui-muted-foreground);font-size:12px}
    #|.mmui-calendar-empty{box-sizing:border-box;min-height:36px}
    #|.mmui-calendar-outside{opacity:.45}
    #|.mmui-calendar-today{border:1px solid var(--mmui-primary);font-weight:600}
    #|.mmui-date-picker-content{display:flex;flex-direction:column;gap:12px;min-width:252px}
    #|.mmui-date-picker-presets{display:flex;flex-wrap:wrap;gap:8px}
    #|.mmui-chart{min-width:0;box-sizing:border-box;color:var(--mmui-foreground)}
    #|.mmui-chart-legend,.mmui-chart-legend-content{display:flex;flex-wrap:wrap;align-items:center;justify-content:center;gap:16px}
    #|.mmui-chart-legend-item,.mmui-chart-tooltip-item{display:flex;align-items:center;gap:8px;font-size:12px}
    #|.mmui-chart-tooltip{padding:8px 0}
    #|.mmui-chart-tooltip-content{display:flex;flex-direction:column;gap:6px;padding:10px;border:1px solid var(--mmui-border);border-radius:var(--mmui-radius);background:var(--mmui-background);box-shadow:0 4px 12px rgba(0,0,0,.12)}
    #|.mmui-chart-tooltip-label{font-size:12px;font-weight:600}
    #|.mmui-combobox,.mmui-command,.mmui-data-table{display:flex;flex-direction:column;gap:8px;min-width:0}
    #|.mmui-combobox-chips,.mmui-data-table-columns{display:flex;align-items:center;flex-wrap:wrap;gap:6px}
    #|.mmui-combobox-chip{display:flex;align-items:center;gap:4px;padding:2px 8px;border-radius:var(--mmui-radius);background:var(--mmui-muted);color:var(--mmui-foreground)}
    #|.mmui-combobox-collection,.mmui-combobox-group,.mmui-combobox-list,.mmui-command-group,.mmui-command-list{display:flex;flex-direction:column;gap:4px;min-width:0}
    #|.mmui-combobox-label,.mmui-menu-label{padding:8px;font-size:12px;font-weight:600;color:var(--mmui-muted-foreground)}
    #|.mmui-combobox-empty,.mmui-command-empty{padding:16px;text-align:center;font-size:14px;color:var(--mmui-muted-foreground)}
    #|.mmui-combobox-separator,.mmui-command-separator,.mmui-field-separator{height:1px;margin:6px 0;background:var(--mmui-border)}
    #|.mmui-command-shortcut{margin-left:auto;font-size:12px;color:var(--mmui-muted-foreground)}
    #|.mmui-table-scroll{width:100%;box-sizing:border-box}
    #|.mmui-table-header,.mmui-table-body,.mmui-table-footer{display:flex;flex-direction:column;min-width:100%}
    #|.mmui-table-header,.mmui-table-head{font-weight:600}
    #|.mmui-table-footer{background:var(--mmui-muted)}
    #|.mmui-table-caption{padding:12px;text-align:center;font-size:14px;color:var(--mmui-muted-foreground)}
    #|.mmui-table-spanning{width:100%;box-sizing:border-box;border:1px solid var(--mmui-border)}
    #|.mmui-table-span-row{box-sizing:border-box;border-bottom:1px solid var(--mmui-border)}
    #|.mmui-carousel-controls{display:flex;align-items:center;gap:8px}
    #|.mmui-carousel{display:flex;flex-direction:column;gap:8px;min-width:0;overflow:hidden}
    #|.mmui-carousel-content,.mmui-carousel-item{box-sizing:border-box;min-width:0;min-height:0}
    #|.mmui-carousel-previous,.mmui-carousel-next{margin:0;padding:6px 10px;border:1px solid var(--mmui-border);border-radius:var(--mmui-radius);background:var(--mmui-background);color:var(--mmui-foreground);font-size:14px}
    #|.mmui-resizable{box-sizing:border-box;border:1px solid var(--mmui-border);border-radius:var(--mmui-radius);overflow:hidden}
    #|.mmui-resizable-panel{box-sizing:border-box;min-width:0;min-height:0}
    #|.mmui-resizable-handle{background:var(--mmui-muted);color:var(--mmui-muted-foreground)}
    #|.mmui-scroll-area{width:100%;min-width:0;box-sizing:border-box}
    #|.mmui-navigation-link,.mmui-navigation-menu-link{display:flex;align-items:center;gap:8px;padding:8px 12px;border-radius:var(--mmui-radius);color:var(--mmui-foreground);text-decoration:none}
    #|.mmui-navigation-menu-root{position:relative;min-width:0}
    #|.mmui-navigation-menu-list{display:flex;align-items:center;gap:4px}
    #|.mmui-navigation-menu-item{position:relative;min-width:0}
    #|.mmui-navigation-menu-trigger{margin:0;padding:8px 12px;border:0;border-radius:var(--mmui-radius);background:transparent;color:var(--mmui-foreground);font-size:14px}
    #|.mmui-navigation-menu-content,.mmui-navigation-menu-viewport{box-sizing:border-box;min-width:0;padding:12px;background:var(--mmui-background);color:var(--mmui-foreground)}
    #|.mmui-navigation-menu-viewport-chrome{box-sizing:border-box;border:1px solid var(--mmui-border);border-radius:var(--mmui-radius);background:var(--mmui-background);box-shadow:0 8px 24px rgba(0,0,0,.16);overflow:hidden}
    #|.mmui-navigation-menu-indicator{height:3px;border-radius:2px;background:var(--mmui-primary)}
    #|.mmui-sidebar-provider{display:flex;min-width:0;min-height:0;box-sizing:border-box}
    #|.mmui-sidebar,.mmui-sidebar-surface{box-sizing:border-box;display:flex;flex-direction:column;gap:8px;padding:12px;background:var(--mmui-muted);color:var(--mmui-foreground)}
    #|.mmui-sidebar-trigger{margin:0;padding:8px;border:1px solid var(--mmui-border);border-radius:var(--mmui-radius);background:var(--mmui-background);color:var(--mmui-foreground)}
    #|.mmui-sidebar-rail{padding:0;border:0;background:var(--mmui-border);color:var(--mmui-muted-foreground)}
    #|.mmui-sidebar-header,.mmui-sidebar-footer,.mmui-sidebar-group{display:flex;flex-direction:column;gap:8px;padding:8px;min-width:0}
    #|.mmui-sidebar-content{display:flex;flex:1;flex-direction:column;gap:8px;min-height:0;min-width:0}
    #|.mmui-sidebar-inset{flex:1;min-width:0;box-sizing:border-box;background:var(--mmui-background);color:var(--mmui-foreground)}
    #|.mmui-sidebar-group-label{font-size:12px;font-weight:600;color:var(--mmui-muted-foreground);padding:4px 8px}
    #|.mmui-sidebar-group-content,.mmui-sidebar-menu{display:flex;flex-direction:column;gap:4px;min-width:0}
    #|.mmui-sidebar-menu-item,.mmui-sidebar-menu-sub-item{position:relative;min-width:0}
    #|.mmui-sidebar-menu-button{display:flex;align-items:center;gap:8px;box-sizing:border-box;width:100%;margin:0;padding:8px;border:0;border-radius:var(--mmui-radius);background:transparent;color:var(--mmui-foreground);font-size:14px;text-align:left}
    #|.mmui-sidebar-menu-sub{display:flex;flex-direction:column;gap:4px;margin:0 12px;padding:4px 8px;border-left:1px solid var(--mmui-border)}
    #|.mmui-sidebar-menu-sub-button{display:flex;align-items:center;gap:8px;margin:0;padding:6px 8px;border:0;border-radius:var(--mmui-radius);background:transparent;color:var(--mmui-foreground);font-size:14px}
    #|.mmui-sidebar-group-action,.mmui-sidebar-menu-action{margin:0;padding:4px 8px;border:0;border-radius:var(--mmui-radius);background:transparent;color:var(--mmui-muted-foreground);font-size:12px}
    #|.mmui-sidebar-menu-badge{padding:2px 6px;border-radius:4px;background:var(--mmui-muted);color:var(--mmui-foreground);font-size:12px}
    #|.mmui-sidebar-menu-skeleton{height:32px;border-radius:var(--mmui-radius);background:var(--mmui-border);opacity:.6}
    #|.mmui-sidebar-input{box-sizing:border-box;width:100%;padding:8px;border:1px solid var(--mmui-border);border-radius:var(--mmui-radius);background:var(--mmui-background);color:var(--mmui-foreground);font-size:14px}
    #|.mmui-sidebar-separator{height:1px;margin:4px 8px;background:var(--mmui-border)}
    #|.mmui-sidebar-tooltip{padding:6px 10px;border-radius:var(--mmui-radius);background:var(--mmui-primary);color:var(--mmui-primary-foreground);font-size:12px}
    #|.mmui-message-scroller-viewport{box-sizing:border-box;width:100%;min-width:0}
    #|.mmui-message-scroller-content{display:flex;flex-direction:column;gap:8px;min-width:0}
    #|.mmui-message-scroller-item{min-width:0;box-sizing:border-box}
    #|.mmui-message-scroller-start,.mmui-message-scroller-end{padding:6px 10px;border:1px solid var(--mmui-border);border-radius:var(--mmui-radius);background:var(--mmui-background);color:var(--mmui-foreground);font-size:12px}
    #|.mmui-drawer{box-sizing:border-box;display:flex;flex-direction:column;gap:8px}
    #|.mmui-drawer-handle{width:40px;height:6px;margin:4px auto 8px;border-radius:3px;background:var(--mmui-border)}
    #|.mmui-form-item{display:flex;flex-direction:column;gap:8px}
    #|.mmui-select-content{display:flex;flex-direction:column;gap:4px;padding:4px}
    #|.mmui-indeterminate{opacity:.65}
    #|.mmui-progress-track{overflow:hidden;border-radius:var(--mmui-radius);background:var(--mmui-muted)}
    #|.mmui-toast-title{font-weight:600;font-size:14px}
    #|.mmui-toast-description{font-size:14px;color:var(--mmui-muted-foreground);margin-top:4px}
    #|.mmui-toast-action,.mmui-toast-close{margin:0;padding:6px 10px;border:1px solid var(--mmui-border);border-radius:var(--mmui-radius);background:transparent;color:inherit;font-size:12px}
  )
}
