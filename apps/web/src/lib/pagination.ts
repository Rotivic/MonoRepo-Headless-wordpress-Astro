interface LocalPaginationOptions {
  root: ParentNode;
  itemSelector: string;
  pagination: HTMLElement | null;
  perPage: number;
  empty?: HTMLElement | null;
  onPageChange?: (page: number, totalPages: number) => void;
}

export function setupLocalPagination({
  root,
  itemSelector,
  pagination,
  perPage,
  empty,
  onPageChange,
}: LocalPaginationOptions) {
  if (!pagination) {
    return { refresh: () => undefined };
  }

  let page = 1;
  const prev = pagination.querySelector<HTMLButtonElement>('[data-pagination-prev]');
  const next = pagination.querySelector<HTMLButtonElement>('[data-pagination-next]');
  const status = pagination.querySelector<HTMLElement>('[data-pagination-status]');

  const render = () => {
    const items = Array.from(root.querySelectorAll<HTMLElement>(itemSelector));
    const totalPages = Math.max(1, Math.ceil(items.length / perPage));
    page = Math.min(page, totalPages);
    const start = (page - 1) * perPage;
    const end = start + perPage;

    items.forEach((item, index) => {
      item.hidden = index < start || index >= end;
    });

    pagination.hidden = items.length <= perPage;
    if (empty) empty.hidden = items.length > 0;
    if (prev) prev.disabled = page <= 1;
    if (next) next.disabled = page >= totalPages;
    if (status) status.textContent = `Pagina ${page} de ${totalPages}`;
    onPageChange?.(page, totalPages);
  };

  prev?.addEventListener('click', () => {
    page = Math.max(1, page - 1);
    render();
  });

  next?.addEventListener('click', () => {
    page += 1;
    render();
  });

  render();

  return {
    refresh: (nextPage = 1) => {
      page = nextPage;
      render();
    },
  };
}
