///|
pub fn program(deps : @app_state.Deps) -> @minimoon.Page {
  @minimoon.page(
    id="drafts",
    route=@minimoon.route("pages/drafts/drafts"),
    title="草稿",
    capabilities=[@minimoon.NavigateTo],
    build=context => {
      context
      .bind(deps.work)
      .view2(context.layout(), (model, layout) => {
        @shell.frame(
          layout,
          "草稿",
          "drafts-page",
          scroll_target=if model.confirm is Some(_) {
            "work-confirmation"
          } else {
            ""
          },
          [
            @shell.hero(
              "已保存的想法", "最近保存的排在前面 · 最多 50 条",
              "drafts-hero",
            ),
            @minimoon.div(class="demo-body", [
              @workbench.action(
                "drafts/new",
                "新建草稿",
                @workbench.editor("drafts", mode="new"),
                disabled=model.storage != @app_state.Ready,
              ),
              @workbench.status(model, deps.send),
              @workbench.confirmation(model, deps.send),
              @minimoon.div(class="demo-stack", data_section="saved-drafts", [
                if model.store.records.is_empty() {
                  @shell.card(
                    if model.storage == @app_state.Ready {
                      "还没有已保存草稿"
                    } else {
                      "本地草稿尚未就绪"
                    },
                    [
                      @minimoon.p(
                        if model.storage == @app_state.Ready {
                          "写下第一个想法，然后点击保存到本地。"
                        } else {
                          "请等待或重试读取；读取失败不等于没有数据。"
                        },
                      ),
                    ],
                  )
                } else {
                  @minimoon.nothing()
                },
                @minimoon.keyed_fragment(
                  model.store.records.map(record => {
                    @minimoon.keyed(
                      "draft-" + record.id.to_string(),
                      @shell.card(record.draft.title, [
                        @minimoon.p(class="demo-output", record.draft.note),
                        @minimoon.div(class="demo-actions", [
                          @workbench.action(
                            "drafts/edit-" + record.id.to_string(),
                            "编辑",
                            @workbench.editor(
                              "drafts",
                              mode="edit",
                              id=record.id,
                            ),
                            disabled=model.storage != @app_state.Ready,
                          ),
                          @workbench.action(
                            "drafts/delete-" + record.id.to_string(),
                            "删除…",
                            (deps.send)(
                              @app_state.Choose(@app_state.Delete(record.id)),
                            ),
                            disabled=model.storage != @app_state.Ready,
                          ),
                        ]),
                      ]),
                    )
                  }),
                ),
              ]),
            ]),
          ],
        )
      })
    },
  )
}
